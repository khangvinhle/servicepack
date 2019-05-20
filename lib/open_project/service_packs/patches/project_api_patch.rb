module OpenProject::ServicePacks
  module Patches
    module ProjectApiPatch
      def self.included(base)
        base.class_eval do
          # p -"Patching API\n" # remove this line after testing
          resource :projects do
            route_param :id do
              before do
                @project = Project.find(params[:id])
              end
              mount ::API::V3::ServicePacks::AssignmentsAPI
            end
          end
        end
      end
    end
  end
end