class AssignsController < ApplicationController
  #layout 'admin'
  before_action :find_project_by_project_id
  include SPAssignmentManager

  def assign
    return head 403 unless User.current.allowed_to?(:assign_ServicePacks, @project)

    if assigned?(@project)
      flash[:alert] = "You must unassign first!"
      render_400 and return
    end
    @service_pack = ServicePack.find_by(id: params[:assign][:service_pack_id])
    if @service_pack.nil?
      flash[:alert] = "Service Pack not found"
      render 'show' and return
    end
    if @service_pack.available?
      if assignable = @service_pack.assigns.where(assigned: true).empty?
        assign_to(@service_pack, @project)
        flash[:notice] = "Service Pack #{@service_pack.name} successfully assigned to project #{@project.name}"
        redirect_to action: "show" and return
      else
        # already assigned for another project
        flash[:alert] = "Service Pack #{@service_pack.name} has been already assigned"
        render_400 and return
      end
    end
    flash[:alert] = 'Service Pack not found'
    render_404 and return
  end

  def unassign
    return head 403 unless User.current.allowed_to?(:unassign_ServicePacks, @project)

    if unassigned?(@project)
      flash[:alert] = 'No Service Pack is assigned to this project'
      render_404 and return
    end
    _unassign(@project)
    flash[:notice] = "Unassigned a Service Pack from this project"
    redirect_to action: 'show' and return
  end

  def show
    return head 403 unless
    User.current.allowed_to?(:see_assigned_ServicePacks, @project) ||
    (tmp = User.current.allowed_to?(:assign_ServicePacks, @project)) ||
    (tmp2 = User.current.allowed_to?(:unassign_ServicePacks, @project)) # not allowed

    # assigned now
    if @assignment = @project.assigns.find_by(assigned: true)
      if @assignment.service_pack.unavailable?
        assignment_terminate(@assignment)
        @assignment = nil # overdue
      end
    end
    #binding.pry
    if @assignment.nil?
      # testing only
      if tmp ||= User.current.allowed_to?(:assign_ServicePacks, @project)
        t = ServicePack.where('expired_date >= ?', Date.today) if Rails.env.development?
        @assignment = Assign.new
        @assignables = []
        t.each do |assignable|
          if assignable.assigns.where(assigned: true).empty?
            @assignables << assignable
          end
        end
      end
    else
      @service_pack = @assignment.service_pack
    end
  end
end
