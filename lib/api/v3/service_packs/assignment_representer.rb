module API
  module V3
    module ServicePacks
      class AssignmentRepresenter < ::API::Decorators::Single
        include ::API::Decorators::LinkedResource

        associated_resource :project
        property :service_pack_id
        property :service_pack_name,
                 getter: ->(*) { service_pack.name }
        property :assign_date
        property :unassign_date
        property :remained_units,
                 getter: ->(*) { service_pack.remained_units }

        def _type
          -'Assignment'
        end
      end
    end
  end
end
