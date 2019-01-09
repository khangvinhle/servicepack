module OpenProject::ServicePacks
  module Patches
    module TimeEntryActivityPatch
      def self.included(receiver)
        receiver.class_eval do
          has_many :mapping_rates
          has_many :service_packs, through: :mapping_rates
        end
      end
    end
  end
end

TimeEntryActivity.send(:include, OpenProject::ServicePacks::Patches::TimeEntryActivityPatch)
