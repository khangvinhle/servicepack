module OpenProject::ServicePacks
  module Patches
    module PermittedParamsPatch
      def time_entry
        permitted_params = params.fetch(:time_entry, {}).permit(
          :hours, :comments, :work_package_id, :activity_id, :spent_on, :service_pack_id)
        permitted_params.merge!(custom_field_values(:time_entry, required: false))
      end
    end
  end
end