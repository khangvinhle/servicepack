module OpenProject::ServicePacks
  module Patches
    module TimeEntryPatch
      module ClassMethods
      end
      module InstanceMethods
        def log_consumed_units

          # Find an assignment in effect, if not then stop the logging.
          # Then check the SP in the log against the assignment list.
          # Then find a rate associated with activity_id and sp in effect.
          # Create an SP_entry with the log entry cost.
          # Subtract the remaining counter of SP to the cost.

          assignments = project.assigns.active.pluck(:service_pack_id)
          if assignments.empty?
            errors[:base] << -'Cannot log time because no SP were assigned'
            raise ActiveRecord::Rollback
          end
          unless assignments.include?(service_pack_id)
            errors[:base] << -'The selected Service Pack is not assigned to this project'
            raise ActiveRecord::Rollback
          end
          # binding.pry
          unless sp_assigned = ServicePack.find_by(id: service_pack_id) and sp_assigned.available?
            errors[:base] << -'The selected Service Pack is in frozen status'
            raise ActiveRecord::Rollback
          end
          incur_cost!
        end

        def update_consumed_units
          # First examine the entry
          # then read the service pack related
          # then recalculate the cost in the entry
          # Update the entry
          # Take the delta and subtract to the remained count of SP.
          sp_entry = service_pack_entry
          return if sp_entry.nil?
          
          unless project.assigns.active.find_by(service_pack_id: service_pack_id)
            errors[:base] << -'The selected Service Pack is not assigned to this project'
            raise ActiveRecord::Rollback
          end

          # handle if SP is in unavailable state here - leaving safely

          activity_id_to_log = activity.parent_id || activity.id

          if sp_entry.service_pack_id == service_pack_id
            # if SP is not updated
            old_sp_of_project = sp_entry.service_pack # the SP entry is binded at the point of creation
            units_cost = hours * old_sp_of_project.mapping_rates.find_by(activity_id: activity_id_to_log).units_per_hour
            if units_cost == sp_entry.units
              old_sp_of_project.touch # trigger after callback only, which has an all-revoke waiting
            else
              extra_consumption = units_cost - sp_entry.units
              sp_entry.update(units: units_cost)
              old_sp_of_project.remained_units -= extra_consumption
              old_sp_of_project.save!(context: :consumption)
            end
          else
            # give the old sp its units back
            refund_units_cost! sp_entry # the SP entry is binded at the point of creation
            # calculate the new rate for the new SP
            incur_units_cost! activity_id_to_log
          end
        end

        def get_consumed_units_back
          refund_units_cost!
        end

        private
          # FOR THIS PATCH ONLY

          def refund_units_cost!(sp_entry = service_pack_entry)
            return if sp_entry.nil?
            service_pack = sp_entry.service_pack
            service_pack.remained_units += sp_entry.units
            service_pack.save!(context: :consumption)
          end

          def incur_units_cost!(activity_id_to_log = activity.parent_id || activity.id, sp_entry = service_pack_entry)
            units_cost = hours * service_pack.mapping_rates.find_by(activity_id: activity_id_to_log).units_per_hour
            sp_entry ||= ServicePackEntry.find_or_initialize_by(time_entry_id: id)
            sp_entry.update(service_pack_id: service_pack_id, units: units_cost)
            service_pack.remained_units -= units_cost
            service_pack.save!(context: :consumption)
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
