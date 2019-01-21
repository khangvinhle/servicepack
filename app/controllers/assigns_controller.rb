class AssignsController < ApplicationController
  #layout 'admin'
  before_action :find_project_by_project_id
  include SPAssignmentManager

  def assign
    return head 403 unless @can_assign = User.current.allowed_to?(:assign_ServicePacks, @project)

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
    return head 403 unless @can_unassign = User.current.allowed_to?(:unassign_ServicePacks, @project)

    if unassigned?(@project)
      flash[:alert] = 'No Service Pack is assigned to this project'
      render_404 and return
    end
    _unassign(@project)
    flash[:notice] = 'Unassigned a Service Pack from this project'
    redirect_to action: 'show' and return
  end

  def show
    return head 403 unless
    User.current.allowed_to?(:see_assigned_ServicePacks, @project) ||
    (@can_assign = User.current.allowed_to?(:assign_ServicePacks, @project)) ||
    (@can_unassign = User.current.allowed_to?(:unassign_ServicePacks, @project))
    binding.pry
    if @assignment = @project.assigns.find_by(assigned: true)
      if @assignment.service_pack.unavailable?
        @assignment.terminate
        @assignment = nil # signifying no assignments are in effect
        # as the single one is terminated.
      end
    end
    # binding.pry
    if @assignment.nil?
      # testing only
      if @can_assign ||= User.current.allowed_to?(:assign_ServicePacks, @project)
        # t = ServicePack.where('expired_date >= ?', Date.today) if Rails.env.development?
        @assignment = Assign.new
        @assignables = []
        ServicePack.availables.each do |assignable|
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
