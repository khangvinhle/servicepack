module OpenProject::ServicePacks
  module Patches
    module UpdateContractPatch
      def validate
        if !sp_entry.nil? && model.project.enabled_modules.find_by(name: -'service_packs')
          unless model.project.assigns.active.find_by(service_pack_id: service_pack_id)
            errors.add :service_pack_id, -'This Service Pack is not assigned to this project'
          else
            if ServicePack.find(service_pack_id).remained_units < model.calculate_unit_costs
              errors.add :base, -'Service Pack selected does not have enough units!'
            end
          end
        end
        super
      end
    end
  end
end