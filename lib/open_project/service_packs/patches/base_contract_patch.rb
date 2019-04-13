module OpenProject::ServicePacks
	module Patches
		module BaseContractPatch
			def self.included(receiver)
				receiver.class_eval do
					attribute :service_pack_id
				end
			end
		end
	end
end
