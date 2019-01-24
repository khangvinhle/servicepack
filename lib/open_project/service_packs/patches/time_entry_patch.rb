module OpenProject::ServicePacks
	module Patches
		module TimeEntryPatch
			module ClassMethods
				
			end
			
			module InstanceMethods
				
				def create_sp_entry
					assignment = project.assigns.where(assigned: true).first
					return if assignment.nil?
					# binding.pry
					activity_of_time_entry = (self.activity.parent_id.nil?) ? self.activity : self.activity.parent
					sp_of_project = assignment.service_pack
						
					# return if sp_of_project.nil? or activity_of_time_entry.nil?
					rate = MappingRate.find_by("service_pack_id = ? and activity_id = ?", sp_of_project.id, activity_of_time_entry.id).units_per_hour
						
					# return if rate.nil?
					units_cost = rate * self.hours

					sp_entry = ServicePackEntry.new 
					sp_entry.time_entry = self
					sp_entry.units = units_cost
					sp_of_project.service_pack_entries << sp_entry

					sp_entry.update(:description => "#{activity_of_time_entry.name}")
					sp_of_project.update(:remained_units => "#{sp_of_project.remained_units - units_cost}")					
				end

				def update_sp_entry
					#check if the project has been assigned a service pack
					assignment = project.assigns.where(assigned: true).first
					binding.pry
					return if assignment.nil? or (assignment.service_pack_id != self.service_pack_entry.id)
					activity_of_time_entry = (self.activity.parent_id.nil?) ? self.activity : self.activity.parent
					sp_of_project = assignment.service_pack
					rate = MappingRate.find_by("service_pack_id = ? and activity_id = ?", sp_of_project.id, activity_of_time_entry.id).units_per_hour
					units_cost = rate * self.hours

					sp_entry = self.service_pack_entry
					if units_cost < sp_entry.units 
						sp_of_project.update(:remained_units => "#{sp_of_project.remained_units + (units_cost - sp_entry.units).abs}")					
					elsif units_cost > sp_entry.units 
					 	sp_of_project.update(:remained_units => "#{sp_of_project.remained_units - (units_cost - sp_entry.units).abs}") 
					end
					sp_entry.units = units_cost
					sp_entry.update(:description => "#{activity_of_time_entry.name}")
					
				end

				def delete_units
					assignment = project.assigns.where(assigned: true).first
					return if assignment.nil? or (assignment.service_pack_id != self.service_pack_entry.id)
					sp_entry = self.service_pack_entry
					sp_of_project = assignment.service_pack
					sp_of_project.update(:remained_units => "#{sp_of_project.remained_units + sp_entry.units}")
				end


			end
			
			def self.included(receiver)
				receiver.extend         ClassMethods
				receiver.send :include, InstanceMethods
				receiver.class_eval do
					has_one :service_pack_entry, dependent: :destroy
					after_create :create_sp_entry
					after_update :update_sp_entry
					before_destroy :delete_units
				end
			end
		end
	end
end