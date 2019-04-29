module OpenProject::ServicePacks
  module Patches
    module TimeEntryPatch
      module InstanceMethods
        def log_consumed_units
          return unless project.enabled_modules.find_by(name: -'service_packs')

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
          incur_units_cost!
        end

        def update_consumed_units
          unless project.enabled_modules.find_by(name: -'service_packs')
            # SP must not change if module is not on
            # and PermittedParams won't see @project
            service_pack_id = service_pack_id_in_database # ActiveRecord::AttributeMethods::Dirty
            return
          end

          sp_entry = service_pack_entry
          return if sp_entry.nil?

          unless project.assigns.active.find_by(service_pack_id: service_pack_id)
            errors[:base] << -'The selected Service Pack is not assigned to this project'
            raise ActiveRecord::Rollback
          end

          activity_id_to_log = activity.parent_id || activity.id

          # if SP is not updated
          if sp_entry.service_pack_id == service_pack_id
            old_sp_of_project = sp_entry.service_pack # the SP entry is binded at the point of creation
            units_cost = hours * old_sp_of_project.mapping_rates.find_by(activity_id: activity_id_to_log).units_per_hour
            if units_cost != sp_entry.units
              extra_consumption = units_cost - sp_entry.units
              sp_entry.update!(units: units_cost)
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
          refund_units_cost! unless project.enabled_modules.find_by(name: -'service_packs')
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

          if service_pack.remained_units - units_cost < 0
            errors[:base] << -'The remained unit of the selected service pack is not enough!'
            raise ActiveRecord::Rollback
          end

          sp_entry ||= ServicePackEntry.new(time_entry_id: id) # why this method is a !
          sp_entry.update!(service_pack_id: service_pack_id, units: units_cost)
          service_pack.remained_units -= units_cost
          service_pack.save!(context: :consumption)

          if service_pack.remained_units < service_pack.threshold1
            User.where('admin = 1').find_each do |u|
              ServicePacksMailer.notify_under_threshold1(u, service_pack).deliver
            end
          end

          if service_pack.remained_units < service_pack.threshold2
            User.where('admin = 1').find_each do |u|
              ServicePacksMailer.notify_under_threshold2(u, service_pack).deliver
            end
          end

          if service_pack.remained_units.zero?
            User.where('admin = 1').find_each do |u|
              ServicePacksMailer.used_up_email(u, service_pack).deliver
            end
          end
        end
      end

      def self.included(receiver)
        receiver.include InstanceMethods
        receiver.class_eval do
          has_one :service_pack_entry, dependent: :destroy
          belongs_to :service_pack
          after_create :log_consumed_units
          before_update :update_consumed_units # to stop persisting changed SP
          before_destroy :get_consumed_units_back
          # validates :service_pack_id, numericality: {only_integer: true, greater_than: 0}, allow_nil: true
        end
      end
    end
  end
end
