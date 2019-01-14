class SPAssignmentManager
	# Implementation is subject to change.
	def assign_to(service_pack, project)
		if service_pack.available? 
			if assignable = service_pack.assigns.where(assigned: true).empty?
				ActiveRecord::Base.transaction do
					# one query only
					project.assigns.update_all!(assigned: false)
					@assign_record = ServicePack.assigns.find_by(project_id: project.id) || project.assigns.new
					@assign_record.assigned = true
					@assign_record.service_pack_id = service_pack.id
					@assign_record.save!
				rescue return :failed
				end
				return :successful
			else
				return :owned
		end
		return :unassignable
	end
	def unassign(project)
		return nil unless @assignment = project.assigns.find_by(assigned: true)
		@assignment.assigned = false
		@assignment.save!
		true
	end
	def assigned?(project)
		project.assigns.where(assigned: true).empty?
	end
	def assignment_terminate(assignment)
		assignment.assigned = false
		assignment.save!
	end
	def assignment_overdue?(assignment)
		assignment.service_pack.unavailable?
	end
end
