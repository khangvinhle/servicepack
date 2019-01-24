module OpenProject::ServicePacks
	module Patches
  		module EnumerationPatch
			module ClassMethods
				
			end
		
			module InstanceMethods
				def update_sp_rates
					binding.pry
		        	if (type == "TimeEntryActivity" and self.parent_id.nil?)
		        		activity = TimeEntryActivity.find_by id: "#{self.id}"
		        		ServicePack.find_each do |sp| 
		        			sp.time_entry_activities << activity
		        		end
		        	end
		        end
			end
		
			def self.included(receiver)
				receiver.extend         ClassMethods
				receiver.send :include, InstanceMethods

				receiver.class_eval do
					after_create :update_sp_rates
				end
			end
		end
  	end
end

Enumeration.send(:include, OpenProject::ServicePacks::Patches::EnumerationPatch)
