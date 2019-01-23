module OpenProject::ServicePacks
  module Patches
    module TimeEntryActivityPatch

      def self.included(receiver)
        
        receiver.class_eval do
          has_many :mapping_rates, inverse_of: :activity, foreign_key: :activity_id, dependent: :destroy
          has_many :service_packs, through: :mapping_rates
          after_create :update_service_pack_rates
        end
      
      end


    end
  end
end

TimeEntryActivity.send(:include, OpenProject::ServicePacks::Patches::TimeEntryActivityPatch)
