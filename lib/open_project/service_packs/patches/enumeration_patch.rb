=begin
module OpenProject::ServicePacks
	module Patches
  		module EnumerationPatch
			module ClassMethods
				
			end
		
			module InstanceMethods
				def update_sp_rates
		          if (type == "TimeEntryActivity" && self.project_id.nil? && self.parent_id.nil?)
		          	ServicePacks.find_each |service_pack| do
		          		service_pack.mapping_rates << self 
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
=end
