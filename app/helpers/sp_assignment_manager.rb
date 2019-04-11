module SPAssignmentManager
	# Implementation is subject to change.
	def assign_to(service_pack, project)
		# binding.pry
		ActiveRecord::Base.transaction do
			# one query only
			@assignment = service_pack.assigns.find_by(project_id: project.id) || project.assigns.new
			@assignment.assigned = true
			@assignment.assign_date = Date.today
			@assignment.unassign_date = service_pack.expired_date
			@assignment.service_pack_id = service_pack.id if @assignment.new_record?
			@assignment.save!
		end
	end
	def _unassign(project)
		# params should be assignment
		assigned?(project)&.terminate # ruby >= 2.3.0 "safe navigation operator"
	end

	# these function only works with 1-n assignment
	# to be deprecated

	def unassigned?(project)
		!assigned?(project)
	end
	def assigned?(project)
		Rails.logger.debug { -'1-n assignment will be deprecated' }
		p -'1-n assignment will be deprecated\n'
		@_assignment ||= project.assigns.find_by(assigned: true)
	end
end
