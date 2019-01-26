module OpenProject::ServicePacks
	module Patches
		module TimeEntryPatch
			module ClassMethods
				
			end
			
			# pseudocode:
			# Find an assignment in effect, if not leave in peace.
			# Then find a rate associated with activity_id and sp in effect.
			# Find the diff
			# then update Service Pack rem with the diff.

			module InstanceMethods			
				def log_consumed_units
					# Haven't test yet
					# puts "Create Units"
					assignment = Assign.where("project_id = ? and assigned = ?", project.id, true)
					return unless assignment.any?
					spid = assignment.first.service_pack_id
					sp_entry = ServicePackEntry.new(service_pack_id: spid, time_entry_id: self.id)
					t = self.activity
					act_id = t.parent_id || t.id
					rate = MappingRate.find_by("service_pack_id = ? and activity_id = ?", spid, act_id).units_per_hour	
					return if rate.nil?
					units_cost = rate * self.hours
					sp_entry.units = units_cost
					sp_of_project = ServicePack.find_by(id: spid)
					sp_of_project.service_pack_entries << sp_entry
					sp_of_project.update(remained_units: sp_of_project.remained_units - units_cost) 
				end

				def update_consumed_units
					sp_entry = self.service_pack_entry
					return if sp_entry.nil?
					service_pack_id = sp_entry.service_pack_id
					t = self.activity
					activity_id = t.parent_id || t.id
					rate = MappingRate.find_by("service_pack_id = ? and activity_id = ?", service_pack_id, activity_id).units_per_hour
					units_cost = rate * self.hours
					extra_consumption = units_cost - sp_entry.units
					# Keep callbacks for SP. Entries have no callback.
					sp_entry.update(units: units_cost) if extra_consumption != 0
					service_pack = ServicePack.find_by(id: service_pack_id)
					sp_remained_units = service_pack.remained_units - extra_consumption
					service_pack.update(remained_units: sp_remained_units)
				end

				def get_consumed_units_back				
					sp_entry = self.service_pack_entry
					return if sp_entry.nil?
					service_pack = sp_entry.service_pack
					u_remained_units = service_pack.remained_units + sp_entry.units
					service_pack.update(remained_units: u_remained_units)
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