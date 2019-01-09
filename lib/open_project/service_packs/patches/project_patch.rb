module OpenProject::ServicePacks
  module Patches
    module ProjectPatch
      def self.included(receiver)
        receiver.class_eval do
          has_many :assigns
          has_many :service_packs, through: :assigns
        end
      end
    end
  end
end

Project.send(:include, OpenProject::ServicePacks::Patches::ProjectPatch)
