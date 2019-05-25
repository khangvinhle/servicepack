module OpenProject::ServicePacks
  module Patches
    module UpdateContractPatch
      def validate

        # SP Entries are only created on new time entries
        # so if it's nil we skip this check as it's created in a no SP context
        if model.must_recalculate_units_cost?
          unless Assign.active.find_by(service_pack_id: service_pack_id, project_id: model.project_id)
            errors.add :service_pack_id, -'This Service Pack is not assigned to this project'
          else
            if ServicePack.find(service_pack_id).remained_units < model.delta_units_cost
              errors.add :base, -'Service Pack selected does not have enough units!'
            end
          end
        end
        super
      end
    end
  end
end