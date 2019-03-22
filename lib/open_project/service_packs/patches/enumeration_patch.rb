module OpenProject::ServicePacks
	module Patches
		module EnumerationPatch

			module ClassMethods
				
			end
		
			module InstanceMethods
	        # Activities are always created and updated as a new Enumeration
	        # (see EnumerationsController#create, #update and line 117 - 123)
	        # so #TEA patching doesn't work.
				def update_sp_rates
			    	if type == "TimeEntryActivity" && shared?
			        	ServicePack.availables.each do |service_pack|
			          	# service_pack.mapping_rates << self # WRONG: this is NOT a plain Ruby collection!
	              	  	# trying to give a sensible default value
			          		service_pack.mapping_rates.create!(units_per_hour: 0, activity_id: self.id)
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

# Enumeration.send(:include, OpenProject::ServicePacks::Patches::EnumerationPatch)
