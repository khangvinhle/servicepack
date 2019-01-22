module OpenProject::ServicePacks
	module Patches
		module TimeEntryPatch
			module ClassMethods
				
			end
			
			module InstanceMethods
				
				def log_units
					# Haven't test yet
					puts "Create Units"
					sp_entry = ServicePackEntry.new
					assignment = Assign.where("project_id = ? and assigned = ?", project.id, true)
					if (assignment.any?) 
						activity_id = self.activity_id
						service_pack_id = assignment[0].service_pack_id
						rate = MappingRate.find_by("service_pack_id = ? and activity_id = ?", service_pack_id, activity_id).units_per_hour
						units_cost = rate * self.hours
						sp_entry.time_entry = self
						sp_entry.units = units_cost
						sp_entry.save

						service_pack = ServicePack.find_by(id: "#{service_pack_id}")
						sp_remained_units = service_pack.remained_units - units_cost
						service_pack.update(:remained_units => "#{sp_remained_units}")
					else
						return
					end

				end

				def update_units
					puts self
					puts self.id
					puts self.hours
					puts self.comments
					
					sp_entry = self.service_pack_entry
					assignment = Assign.where("project_id = ? and assigned = ?", project.id, true)
					
					if (assignment.any?) 
						activity_id = self.activity_id
						service_pack_id = assignment[0].service_pack_id
						rate = MappingRate.find_by("service_pack_id = ? and activity_id = ?", service_pack_id, activity_id).units_per_hour
						units_cost = rate * self.hours
						
						sp_entry.update(:units => "#{units_cost}")

						diff = units_cost - sp_entry.units 

						service_pack = ServicePack.find_by(id: "#{service_pack_id}")
						if diff < 0
							sp_remained_units = service_pack.remained_units + diff
						else
							sp_remained_units = service_pack.remained_units - diff
						end
						service_pack.update(:remained_units => "#{sp_remained_units}")

					else
						return
					end
				end

				def delete_units
					puts self.id
					puts self.comments
					puts self.activity_id
					puts self.hours

					
					assignment = Assign.where("project_id = ? and assigned = ?", project.id, true)
					
					if (assignment.any?)
						sp_entry = self.service_pack_entry
						service_pack_id = assignment[0].service_pack_id
						service_pack = ServicePack.find_by(id: "#{service_pack_id}")
						update_remained_units = sp_entry.units + service_pack.remained_units
						service_pack.update(:remained_units => "#{update_remained_units}")
						
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
					after_create :log_units
					after_update :update_units
					before_destroy :delete_units
				end
			end
		end
	end
end