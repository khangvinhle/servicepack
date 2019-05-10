module API
  module V3
    module ServicePacks
      class AssignmentCollectionRepresenter < ::API::Decorators::Collection
        element_decorator ::API::V3::ServicePacks::AssignmentRepresenter
      end
    end
  end
end