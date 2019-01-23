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
					if assignment.any?
						sp_entry = ServicePackEntry.new
						service_pack_id = assignment[0].service_pack_id
						rate = MappingRate.find_by("service_pack_id = ? and activity_id = ?", service_pack_id, activity_id).units_per_hour
						sp_entry.time_entry = self
						sp_entry.units = rate * self.hours
						# transaction?
						sp_entry.save!
						service_pack = ServicePack.find_by(id: service_pack_id)
						service_pack.update!(remained_units: service_pack.remained_units - sp_entry.units)
					else
						return
					end

				end

				def update_consumed_units
					# Tested and only works with non-overridden activities. Concerns raised:
					# No analytics capability => inextensible (maybe_check)
					# (which Service Pack is this entry binded to?) (not yet)
					# Also entries can be amended. (check)
					
					assignment = Assign.where("project_id = ? and assigned = ?", project.id, true)
					
					if (assignment.any?)
						sp_entry = self.service_pack_entry
						service_pack_id = assignment[0].service_pack_id
						rate = MappingRate.find_by("service_pack_id = ? and activity_id = ?", service_pack_id, activity_id).units_per_hour
						units_cost = rate * self.hours
						extra_consumption = units_cost - sp_entry.units
						# binding.pry
						# keep callbacks for SP
						sp_entry.update(units: units_cost) if extra_consumption != 0
						service_pack = ServicePack.find_by(id: service_pack_id)
						sp_remained_units = service_pack.remained_units - extra_consumption
						# binding.pry
						service_pack.update(remained_units: sp_remained_units)
					else
						return
					end
				end

				# pseudocode for destroy callback:
				# Get assignment and entry, both must be present or we retreat.
				# Get SP through assignment found
				# Add back units from the entry to the SP

				# The rem count must be allowed to go into the negative.
				# That's why saving used counting is better.

				def get_consumed_units_back				
					assignment = Assign.where("project_id = ? and assigned = ?", project.id, true)
					
					if (assignment.any? && sp_entry = self.service_pack_entry) # old logs
						# sp_entry = self.service_pack_entry
						service_pack_id = assignment[0].service_pack_id
						service_pack = ServicePack.find_by(id: service_pack_id)
						u_remained_units = service_pack.remained_units + sp_entry.units
						service_pack.update(remained_units: u_remained_units)					
					else
						return
					end 	

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