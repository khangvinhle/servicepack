module OpenProject::ServicePacks
	module Patches
		module TimeEntryPatch
			module ClassMethods
				
			end
			
			module InstanceMethods
				def update_units
					@sp_entry = ServicePackEntry.new
					@sp_entry.time_entry = self
					@sp_entry.units = 30
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