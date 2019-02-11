class AssignsController < ApplicationController
  #layout 'admin'
  before_action :find_project_by_project_id
  include SPAssignmentManager

  def assign
    return head 403 unless @can_assign = User.current.allowed_to?(:assign_service_packs, @project)

    if assigned?(@project)
      flash[:alert] = "You must unassign first!"
      render_400 and return
    end
    @service_pack = ServicePack.find_by(id: params[:assign][:service_pack_id])
    if @service_pack.nil?
      flash.now[:alert] = "Service Pack not found"
      render_404 and return
    end
    if @service_pack.available?
        assign_to(@service_pack, @project)
        flash[:notice] = "Service Pack #{@service_pack.name} successfully assigned to project #{@project.name}"
        redirect_to action: "show" and return
    else
      # already assigned for another project
      # constraint need
      flash[:alert] = "Service Pack #{@service_pack.name} has been already assigned"
      render_400 and return
    end
    flash.now[:alert] = 'Service Pack cannot be assigned'
    redirect_to action: "show"
  end

  def unassign
    return head 403 unless @can_unassign = User.current.allowed_to?(:unassign_service_packs, @project)

    if unassigned?(@project)
      flash[:alert] = 'No Service Pack is assigned to this project'
      render_404 and return
    end
    _unassign(@project)
    flash[:notice] = 'Unassigned a Service Pack from this project'
    redirect_to action: 'show' and return
  end

  def show
    # This will lock even admins out if the module is not activated.
    return head 403 unless 
    User.current.allowed_to?(:see_assigned_service_packs, @project) ||
    (@can_assign = User.current.allowed_to?(:assign_service_packs, @project)) ||
    (@can_unassign = User.current.allowed_to?(:unassign_service_packs, @project))

    # binding.pry
    if @assignment = @project.assigns.find_by(assigned: true)
      if @assignment.service_pack.unavailable?
        @assignment.terminate
        @assignment = nil # signifying no assignments are in effect
        # as the single one is terminated.
      end
    end
    # binding.pry
    if @assignment.nil?
      if @can_assign ||= User.current.allowed_to?(:assign_service_packs, @project)
        @assignment = Assign.new
        @assignables = ServicePack.availables
      end
      render 'not_assigned_yet'
      # binding.pry
    else
      @service_pack = @assignment.service_pack
      render 'already_assigned'
    end
  end
  
  # =======================================================
  # :Docs
  # * Limit: Serving JSON only. Intended to restrict to :show.
  # * Purpose:
  # Return a table with consumed units by a Project grouped by service 
  # pack, then activities and sorted from large to small.
  # * Expected Inputs:
  # [project_id]: Sharing the same route with the resourceful default.
  # Put in the link. Mandatory.
  # [start_period]: Beginning of the counting period. As a date. Optional.
  # [end_period]: Ending of the counting period. As a date. Optional.
  # start_period MUST NOT be later than end_period.
  # Both or none of [start_period, end_period] can be present.
  # * Expected Outputs
  # Top class: None
  # Content: Array of object having [name, act_name, consumed]
  # - Name: Name of Service Pack
  # - act_name: Name of activity
  # - consumed: How many units are consumed (in given period)
  # Status: 200
  # * When raising error
  # HTTP 400: Malformed request.
  # =======================================================

  def statistics
    return head 403 unless 
    User.current.allowed_to?(:see_assigned_service_packs, @project) ||
    (@can_assign = User.current.allowed_to?(:assign_service_packs, @project)) ||
    (@can_unassign = User.current.allowed_to?(:unassign_service_packs, @project))
    
    start_day = params[:start_period]&.to_date # ruby >= 2.3.0
    end_day = params[:end_period]&.to_date
    if start_day.nil? ^ end_day.nil?
      render json: { error: 'GET OUT!'}, status: 400 and return
    end

    # Notice: Change max(t4.name) to ANY_VALUE(t4.name) on production builds.
    # MySQL specific >= 5.7.5
    # https://dev.mysql.com/doc/refman/5.7/en/group-by-handling.html

    get_parent_id = <<-SQL
      SELECT id, name,
      CASE WHEN parent_id IS NULL THEN id ELSE parent_id END AS pid
      FROM #{TimeEntryActivity.table_name}
      WHERE type = 'TimeEntryActivity'
      SQL
    body_query = <<-SQL
      SELECT t1.service_pack_id AS spid, max(t4.name) AS name, t3.pid AS pid,
      max(t3.name) AS act_name, sum(t1.units) AS consumed
      FROM #{ServicePackEntry.table_name} t1
      INNER JOIN #{TimeEntry.table_name} t2
      ON t1.time_entry_id = t2.id
      INNER JOIN (#{get_parent_id}) t3
      ON t2.activity_id = t3.id
      INNER JOIN #{ServicePack.table_name} t4
      ON t1.service_pack_id = t4.id
      SQL
    group_clause = <<-SQL
      GROUP BY t1.service_pack_id, t3.pid
      ORDER BY consumed DESC
      SQL
    where_clause = "WHERE t2.project_id = ?"
    where_clause << (start_day.nil? ? '' : ' AND t1.created_at BETWEEN ? AND ?')
    query = body_query + where_clause + group_clause
    par = start_day.nil? ? [query, params[@project.id]] : [query, params[@project.id], start_day, end_day]
    sql = ActiveRecord::Base.send(:sanitize_sql_array, par)
    render json: ActiveRecord::Base.connection.exec_query(sql).to_hash, status: 200
  end
end
