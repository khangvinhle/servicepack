module OpenProject::ServicePacks
	module Patches
		module TimeEntryPatch
			module ClassMethods
				
			end
			
			module InstanceMethods
				def update_units
					# Haven't test yet
					
					# sp_entry = ServicePackEntry.new
					# project_id = self.project_id
					# assignment = Assign.where("project_id = ? and assigned = ?", project_id, true)
					# if (assignment.any?) 
					# 	activity_id = self.activity_id
					# 	service_pack_id = assignment[0].service_pack_id
					# 	rate = MappingRate.find_by("service_pack_id = ? and activity_id = ?", service_pack_id, activity_id).units_per_hour
					# 	units_cost = rate * self.hours
					# 	sp_entry = self
					# 	sp_entry.units = units_cost
					# 	sp_entry.save  

					# 	service_pack = ServicePack.find_by(service_pack_id)
					# 	service_pack.remained_units -= units_cost
					# else
					# 	return
					# end
				end
			end
			
			def self.included(receiver)
				receiver.extend         ClassMethods
				receiver.send :include, InstanceMethods
				receiver.class_eval do
					has_one :service_pack_entry
					before_save :update_units
				end
			end
		end
	end
end