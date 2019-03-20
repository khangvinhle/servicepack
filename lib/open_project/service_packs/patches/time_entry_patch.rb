module OpenProject::ServicePacks
	module Patches
		module TimeEntryPatch
			module ClassMethods

			end


			# pseudocode:
			# Find an assignment in effect, if not leave in peace.
			# Then find a rate associated with activity_id and sp in effect.
			# Create an SP_entry with the log entry cost.
			# Subtract the remaining counter of SP to the cost.

			module InstanceMethods

				def log_consumed_units
					assignment = project.assigns.where(assigned: true).first
					if assignment.nil?
            			self.errors[:base] << "Cannot log time because none SP was assigned"
            			raise ActiveRecord::Rollback
          			end
					activity_of_time_entry_id = self.activity.parent_id || self.activity.id
					sp_of_project = assignment.service_pack
					rate = sp_of_project.mapping_rates.find_by(activity_id: activity_of_time_entry_id).units_per_hour
					units_cost = rate * self.hours
					# binding.pry
					sp_entry = ServicePackEntry.new(time_entry_id: id, units: units_cost)
					sp_of_project.service_pack_entries << sp_entry
					sp_of_project.remained_units -= units_cost
					sp_of_project.save(context: :consumption)
=begin
          if sp_of_project.remained_units <= 0
            assignment.update(assigned: false)
            admin_users = User.where(admin: true)
            admin_users.each do |admin_user|
              ServicePacksMailer.used_up_email(admin_user, sp_of_project).deliver_now
            end
          end
=end

        end


				def update_consumed_units
					# First examine the entry
					# then read the service pack related
					# then recalculate the cost in the entry
					# Update the entry
					# Take the delta and subtract to the remained count of SP.

					sp_entry = self.service_pack_entry
					return if sp_entry.nil?
					sp_of_project = sp_entry.service_pack # the SP entry is binded at the point of creation
					activity_of_time_entry_id = self.activity.parent_id || self.activity.id
					rate = sp_of_project.mapping_rates.find_by(activity_id: activity_of_time_entry_id).units_per_hour
					units_cost = rate * self.hours

					extra_consumption = units_cost - sp_entry.units
					# Keep callbacks for SP. Entries have no callback.
					sp_entry.update(units: units_cost) if extra_consumption != 0
					sp_of_project.remained_units -= extra_consumption
					sp_of_project.save(context: :consumption)
				end

				def get_consumed_units_back
					sp_entry = self.service_pack_entry
					return if sp_entry.nil?
					service_pack = sp_entry.service_pack
					service_pack.remained_units += sp_entry.units
					service_pack.save
				end

			end

			def self.included(receiver)
				receiver.extend         ClassMethods
				receiver.send :include, InstanceMethods
				receiver.class_eval do
					has_one :service_pack_entry, dependent: :destroy
					after_create :log_consumed_units
					after_update :update_consumed_units
					before_destroy :get_consumed_units_back
				end
			end

		end
	end
end