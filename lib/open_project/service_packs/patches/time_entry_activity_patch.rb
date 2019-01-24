module OpenProject::ServicePacks
  module Patches
    module TimeEntryActivityPatch

        module ClassMethods
          
        end
      
        module InstanceMethods
            def update_sp_rates
                  if (self.parent_id.nil? and self.project_id.nil?)
                    binding.pry
                  end
            end 
        end

        def self.included(receiver)
            receiver.extend         ClassMethods
            receiver.send :include, InstanceMethods
            
            receiver.class_eval do
              has_many :mapping_rates, foreign_key: :activity_id, inverse_of: 'activity', dependent: :destroy 
              has_many :service_packs, through: :mapping_rates
              # after_create :update_sp_rates
            end 
        end
    
    end
  end
end

TimeEntryActivity.send(:include, OpenProject::ServicePacks::Patches::TimeEntryActivityPatch)
