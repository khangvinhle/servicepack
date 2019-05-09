module API
  module V3
    module ServicePacks
      class AssignmentCollectionRepresenter < ::API::Decorators::Single
      	property :count, getter: ->(*) { count }
      	collection :elements,
      				      getter: ->(*) {
      					       represented.map {|thing| AssignmentRepresenter.create(thing, current_user: current_user)}
      				      },
      				      exec_context: :decorator,
      				      embedded: false

      	def _type
      		-'Assignments'
      	end
      end
    end
  end
end