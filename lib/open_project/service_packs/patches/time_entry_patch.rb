module OpenProject::ServicePacks
  module Patches
    module TimeEntryPatch
      module InstanceMethods
        def log_consumed_units
          unless project.enabled_modules.find_by(name: -'service_packs')
            service_pack_id = nil
            return
          end
          incur_units_cost!
        end

        def update_consumed_units
          # check again because of Costs plugin
          unless must_recalculate_units_cost?
            # SP must not change if module is not on
            # and PermittedParams won't see @project
            service_pack_id = service_pack_id_in_database # ActiveRecord::AttributeMethods::Dirty
            return
          end
          sp_entry = service_pack_entry
          # if SP is not updated
          if sp_entry.service_pack_id == service_pack_id
            if delta_units_cost(sp_entry) != 0.0
              sp_entry.update!(units: @units_cost)
              old_sp_of_project.remained_units -= delta_units_cost
              old_sp_of_project.save!(context: :consumption)
            end
          else
            # give the old sp its units back
            refund_units_cost! sp_entry # the SP entry is binded at the point of creation
            # calculate the new rate for the new SP
            incur_units_cost! sp_entry
          end
        end

        def get_consumed_units_back
          # lose units when SP module is disabled
          refund_units_cost! if project.enabled_modules.find_by(name: -'service_packs')
        end


        def calculate_units_cost
          return @units_cost if defined? @units_cost
          activity_id_to_log = activity.parent_id || activity_id
          @units_cost = hours * service_pack.mapping_rates.find_by(activity_id: activity_id_to_log).units_per_hour
        end

        def delta_units_cost(sp_entry = service_pack_entry)
          # return calculate_units_cost if new_record?
          @delta_cost ||= (sp_entry.service_pack_id == service_pack_id ? calculate_units_cost - sp_entry.units
                               : calculate_units_cost)
        end

        def must_recalculate_units_cost?
          return @have_to_rec_units_cost if defined? @have_to_rec_units_cost
          @have_to_rec_units_cost = EnabledModule.find_by(name: -'service_packs', project_id: project_id) && service_pack_entry.nil?
        end

        private

        # FOR THIS PATCH ONLY

        def refund_units_cost!(sp_entry = service_pack_entry)
          return if sp_entry.nil?
          service_pack = sp_entry.service_pack
          service_pack.remained_units += sp_entry.units
          service_pack.save!(context: :consumption)
        end

        def incur_units_cost!(sp_entry = service_pack_entry)
          sp_entry ||= ServicePackEntry.new(time_entry_id: id) # why this method is a !
          sp_entry.update!(service_pack_id: service_pack_id, units: calculate_units_cost)
          service_pack.remained_units -= @units_cost
          service_pack.save!(context: :consumption)

          # should be an after_commit callback

          if !service_pack.threshold1_notified && service_pack.remained_units < service_pack.threshold1
            # line 306, lib/open_project/configuration.rb
            # see from line 399 for more details
            OpenProject::Configuration.reload_mailer_configuration!
            User.where(admin: true).find_each do |u|
              ServicePacksMailer.notify_under_threshold1(u.mail, service_pack).deliver_later
            end

            unless service_pack.additional_notification_email.blank?
              ServicePacksMailer.notify_under_threshold1(service_pack.additional_notification_email, service_pack).deliver_later
            end

            service_pack.update_column :threshold1_notified,true
          end

          if !service_pack.threshold2_notified && service_pack.remained_units < service_pack.threshold2
            OpenProject::Configuration.reload_mailer_configuration!
            User.where(admin: true).find_each do |u|
              ServicePacksMailer.notify_under_threshold2(u.mail, service_pack).deliver_later
            end

            unless service_pack.additional_notification_email.blank?
              ServicePacksMailer.notify_under_threshold2(service_pack.additional_notification_email, service_pack).deliver_later
            end

            service_pack.update_column :threshold2_notified,true
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
        end
      end
    end
  end
end
