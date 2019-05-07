module API
  module V3
    module ServicePacks
      class AssignmentsAPI < ::API::OpenProjectAPI
        namespace :assignments do
          before do
            # maybe the permssion needs to be reconsidered.
            # the representer display (almost) everything.
            authorize_any(%i(log_time
                             edit_time_entries edit_own_time_entries
                             manage_project_activities
                             see_assigned_service_packs
                             assign_service_packs
                             unassign_service_packs), projects: @project) # 4 first permissions are for time logging
          end

          get do
            unless @project.enabled_modules.find_by(name: -'service_packs')
              raise ::API::Errors::ErrorsBase.new(message: -'Service Packs module is disabled for this project')
            end
            
            @assignments = @project.assigns.active.preload(:service_pack)
            raise ::API::Errors::NotFound.new(message: -'No active assignments found') if @assignments.empty?
            ::API::V3::ServicePacks::AssignmentCollectionRepresenter.new(@assignments, @assignments.length, -'',
                                                                         current_user: current_user)
          end
        end
      end
    end
  end
end