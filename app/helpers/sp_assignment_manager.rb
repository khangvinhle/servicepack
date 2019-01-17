module SPAssignmentManager
	# Implementation is subject to change.
	def assign_to(service_pack, project)
		#binding.pry
		ActiveRecord::Base.transaction do
			# one query only
			# project.assigns.update_all(assigned: false)
			@assignment = service_pack.assigns.find_by(project_id: project.id) || project.assigns.new
			@assignment.assigned= true
			@assignment.assign_date = Date.today
			@assignment.service_pack_id = service_pack.id
			@assignment.save!
		end
	end
	def _unassign(project)
		return nil unless @assignment = project.assigns.find_by(assigned: true)
		#binding.pry
		assignment_terminate(@assignment)
	end
	def assigned?(project)
		!(project.assigns.where(assigned: true).empty?)
	end
	def assignment_terminate(assignment)
		assignment.assigned = false
		assignment.save!
	end
	def assignment_overdue?(assignment)
		assignment.service_pack.unavailable?
	end

end
