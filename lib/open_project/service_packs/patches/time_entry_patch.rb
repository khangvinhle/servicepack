module OpenProject::ServicePacks
  module Patches
    module TimeEntryPatch
      module ClassMethods
      end
      module InstanceMethods
        def log_consumed_units
          # Find an assignment in effect, if not leave in peace.
          # Then find a rate associated with activity_id and sp in effect.
          # Create an SP_entry with the log entry cost.
          # Subtract the remaining counter of SP to the cost.

          assignments = project.assigns.where(assigned: true)
          if assignments.nil?
            errors[:base] << 'Cannot log time because none SP was assigned'
            raise ActiveRecord::Rollback
          end

          unless assignments.pluck(:service_pack_id).include?(service_pack_id)
            errors[:base] << 'The selected service pack is not assigned to this project'
            raise ActiveRecord::Rollback
          end

          activity_of_time_entry_id = activity.parent_id || activity.id
          sp_of_project = ServicePack.readonly(false).find_by(id: service_pack_id)
          rate = sp_of_project.mapping_rates.find_by(activity_id: activity_of_time_entry_id).units_per_hour
          units_cost = rate * hours
          sp_entry = ServicePackEntry.new(time_entry_id: id, units: units_cost)
          sp_of_project.service_pack_entries << sp_entry
          sp_of_project.update(remained_units: sp_of_project.remained_units - units_cost)
        end

        def update_consumed_units
          # First examine the entry
          # then read the service pack related
          # then recalculate the cost in the entry
          # Update the entry
          # Take the delta and subtract to the remained count of SP.
          sp_entry = service_pack_entry
          return if sp_entry.nil?

          old_sp_of_project = sp_entry.service_pack # the SP entry is binded at the point of creation

          unless project.assigns.where(assigned: true).pluck(:service_pack_id).include?(old_sp_of_project.id)
            errors[:base] << 'The selected service pack is not assigned to this project'
            raise ActiveRecord::Rollback
          end

          new_sp_of_project = ServicePack.find_by(id: service_pack_id)
          activity_of_time_entry_id = activity.parent_id || activity.id

          if old_sp_of_project.id == new_sp_of_project.id
            rate = old_sp_of_project.mapping_rates.find_by(activity_id: activity_of_time_entry_id).units_per_hour
            units_cost = rate * hours
            extra_consumption = units_cost - sp_entry.units
            # Keep callbacks for SP. Entries have no callback.
            sp_entry.update(units: units_cost) if extra_consumption != 0
            old_sp_of_project.remained_units -= extra_consumption
            binding.pry
            old_sp_of_project.save!(context: :consumption)
          else
            # give the old sp its units back
            old_sp_of_project.remained_units += sp_entry.units
            binding.pry
            old_sp_of_project.save!(context: :consumption)
            # calculate the new rate for the new sp
            new_rate = new_sp_of_project.mapping_rates.find_by(activity_id: activity_of_time_entry_id).units_per_hour
            new_unit_cost = new_rate * hours
            sp_entry.update(service_pack_id: new_sp_of_project.id, units: new_unit_cost)
          end
        end

        def get_consumed_units_back
          sp_entry = service_pack_entry
          return if sp_entry.nil?
          service_pack = sp_entry.service_pack
          service_pack.remained_units += sp_entry.units
          service_pack.save
        end
      end

      def self.included(receiver)
        receiver.extend ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          has_one :service_pack_entry, dependent: :destroy
          belongs_to :service_pack
          after_create :log_consumed_units
          after_update :update_consumed_units
          before_destroy :get_consumed_units_back
        end
      end
    end
  end
end
