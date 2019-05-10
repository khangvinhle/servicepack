module OpenProject::ServicePacks
  module Patches
    module CreateContractPatch
      def validate
        # binding.pry
        if EnabledModule.find_by(name: -'service_packs', project_id: model.project_id)
          unless Assign.active.find_by(service_pack_id: service_pack_id, project_id: model.project_id)
            errors.add :service_pack_id, -'This Service Pack is not assigned to this project'
          else
            if ServicePack.find(service_pack_id).remained_units < model.calculate_units_cost
              errors.add :base, -'Service Pack selected does not have enough units!'
            end
          end
        end
        super
      end
    end
  end
end