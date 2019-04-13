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

  def unassign_from(service_pack, project)
    ActiveRecord::Base.transaction do
      @assignment = service_pack.assigns.active.find_by(project_id: project.id)
      raise ActiveRecord::RecordNotFound unless @assignment
      @assignment.terminate!
    end
  end
end
