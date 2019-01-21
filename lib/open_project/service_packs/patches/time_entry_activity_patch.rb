module OpenProject::ServicePacks
  module Patches
    module TimeEntryActivityPatch

      def self.included(receiver)
        
        receiver.class_eval do
          has_many :mapping_rates, inverse_of: :activity, foreign_key: :activity_id, dependent: :destroy
          has_many :service_packs, through: :mapping_rates
          after_create :update_service_pack_rates, if: :shared?
        end
      
      end

      def update_service_pack_rates

        ServicePacks.each do |service_pack| # wrong order :D
          # service_pack.mapping_rates << self # WRONG: this is NOT a plain Ruby collection!
          service_pack.mapping_rates.new(units_per_hour: 0).save! # default rate.
        end

      end

    end
  end
end

TimeEntryActivity.send(:include, OpenProject::ServicePacks::Patches::TimeEntryActivityPatch)
