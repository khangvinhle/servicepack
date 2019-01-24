module OpenProject::ServicePacks
	module Patches
		module TimeEntryPatch
			module ClassMethods
				
			end
			
			module InstanceMethods
				
				def log_units
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

				def update_units
		
				end

				def delete_units
					 	

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