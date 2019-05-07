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

          helpers do
            def lite_etag
              key = @assignments.map {|a| "#{a.id}!#{a.service_pack_id}!#{a.updated_at}"}.join(-'|')
              hash_to_compare = Digest::SHA1.hexdigest(key)
              error!(-'Not Modified', 304) if request.headers[-'If-None-Match'] == hash_to_compare
              header -'ETag', hash_to_compare
            end
          end

          get do
            unless @project.enabled_modules.find_by(name: -'service_packs')
              raise ::API::Errors::ErrorBase.new(422, -'Service Packs module is disabled for this project')
            end
            
            @assignments = @project.assigns.active.preload(:service_pack)
            # raise ::API::Errors::NotFound.new(message: -'No Service Packs are assigned to this project') if @assignments.empty?
            lite_etag
            # just an empty array should be enough
            ::API::V3::ServicePacks::AssignmentCollectionRepresenter.new(@assignments, @assignments.length, -'',
                                                                         current_user: current_user)
          end
        end
      end
    end
  end
end