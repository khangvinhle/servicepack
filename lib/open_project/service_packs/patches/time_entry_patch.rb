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
					sp_entry = ServicePackEntry.new(service_pack_id: spid)
					t = self.activity
					act_id = t.parent_id || t.id
					rate = MappingRate.find_by("service_pack_id = ? and activity_id = ?", spid, act_id).units_per_hour
					sp_entry.time_entry = self
					sp_entry.units = rate * self.hours
					# transaction?
					sp_entry.save!
					service_pack = ServicePack.find_by(id: spid)
					service_pack.update!(remained_units: service_pack.remained_units - sp_entry.units)
				end

				def update_consumed_units
					binding.pry
					return unless sp_entry = self.service_pack_entry
					spid = sp_entry.service_pack_id
					t = self.activity
					act_id = t.parent_id || t.id
					rate = MappingRate.find_by("service_pack_id = ? and activity_id = ?", spid, act_id).units_per_hour
					units_cost = rate * self.hours
					extra_consumption = units_cost - sp_entry.units
					# keep callbacks for SP
					sp_entry.update(units: units_cost) if extra_consumption != 0
					service_pack = ServicePack.find_by(id: spid)
					sp_remained_units = service_pack.remained_units - extra_consumption
					# binding.pry
					service_pack.update(remained_units: sp_remained_units)
				end

				def get_consumed_units_back				
					return unless sp_entry = self.service_pack_entry
					spid = sp_entry.service_pack_id
					service_pack = ServicePack.find_by(id: spid)
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