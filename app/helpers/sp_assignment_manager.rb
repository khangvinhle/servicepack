module SPAssignmentManager
  def assign_to(service_pack, project)
    # binding.pry
    ActiveRecord::Base.transaction do
      assignment = service_pack.assigns.find_or_initialize_by(project_id: project.id)
      assignment.update!(assigned: true, assign_date: Date.today, unassign_date: service_pack.expired_date)
    end
  end

  def unassign_from(service_pack, project)
    ActiveRecord::Base.transaction do
      assignment = service_pack.assigns.active.find_by!(project_id: project.id)
      assignment.terminate!
    end
  end
end
