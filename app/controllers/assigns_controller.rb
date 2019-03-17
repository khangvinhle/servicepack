class AssignsController < ApplicationController
  #layout 'admin'
  before_action :find_project_by_project_id
  include SPAssignmentManager

  def assign
    # binding.pry
    return head 403 unless @can_assign = User.current.allowed_to?(:assign_service_packs, @project)

    if assigned?(@project)
      flash.now[:alert] = -'You must unassign first!'
      render_400 and return
    end
    @service_pack = ServicePack.find_by(id: params[:assign][:service_pack_id])
    if @service_pack.nil?
      flash.now[:alert] = -'Service Pack not found'
      render_404 and return
    end
    if @service_pack.available?
      # binding.pry
      assign_to(@service_pack, @project)
      flash.now[:notice] = "Service Pack '#{@service_pack.name}' successfully assigned to project '#{@project.name}'"
      render -'already_assigned' and return
    else
      # already assigned for another project
      # constraint need
      flash.now[:alert] = "Service Pack '#{@service_pack.name}' has been already assigned"
      render_400 and return
    end
    flash.now[:alert] = 'Service Pack cannot be assigned'
    redirect_to action: :show
  end

  def unassign
    return head 403 unless @can_unassign = User.current.allowed_to?(:unassign_service_packs, @project)

    if unassigned?(@project)
      flash[:alert] = 'No Service Pack is assigned to this project'
      render_404 and return
    end
    _unassign(@project)
    flash[:notice] = 'Unassigned a Service Pack from this project'
    redirect_to action: :show and return
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
        @assignables = ServicePack.availables
        if @assignables.exists?
          @assignment = Assign.new
          render -'not_assigned_yet' and return
        end
      end
      render -'unassignable'
      # binding.pry
    else
      @service_pack = @assignment.service_pack
      render -'already_assigned'
    end
  end
  
  def transfer
    return head 403 unless User.current.allowed_to?(:transfer_service_packs, @project)

    unless @assignment = assigned?(@project)
      flash.now[:alert] = -'Project has not been assigned'
      render_400 and return
    end
    if params[:sp_to].to_i == @assignment.service_pack_id
      flash[:alert] = -'Transfering to the same SP'
      redirect_to action: :show and return
    end
    unless sp_to = ServicePack.find_by(id: params[:sp_to])
      flash.now[:alert] = -'Service Pack not found'
      render_400 and return
    end
    if sp_to.unavailable?
      flash[:alert] = -'Service Pack cannot be assigned'
      redirect_to action: :show and return
    end

    assigned_time = @assignment.updated_at.strftime(-'%Y-%m-%d %H:%M:%S')
    binding.pry

    sp_from_id = @assignment.service_pack_id
    get_parent_id = <<-SQL
      SELECT id, COALESCE(parent_id, id) AS pid
      FROM #{TimeEntryActivity.table_name}
      WHERE type = 'TimeEntryActivity'
      SQL
    join_clause = <<-SQL
      service_pack_entries t1
      INNER JOIN time_entries t2
      ON t1.time_entry_id = t2.id AND t1.updated_at >= '#{assigned_time}'
      AND t2.project_id = #{@project.id}
      INNER JOIN (#{get_parent_id}) t3
      ON t2.activity_id = t3.id
      INNER JOIN mapping_rates t4
      ON t3.pid = t4.activity_id AND t4.service_pack_id = #{sp_to.id}
      SQL

    # 1. Return units back to SP_from
    # 2. Change all units "marked" to SP_to and update consumption
    # 3. Update assignment
    # 4. Update all the entries --

    queries = []

    queries << <<-SQL
              UPDATE service_packs 
              SET updated_at = CURRENT_TIMESTAMP(),
              remained_units = remained_units + 
                (SELECT SUM(units)
                FROM service_pack_entries t1
                INNER JOIN #{TimeEntry.table_name} t2
                ON t1.time_entry_id = t2.id AND t2.project_id = #{@project.id}
                WHERE t1.updated_at >= '#{assigned_time}'
                )
              WHERE id = #{sp_from_id}
              SQL
    queries << <<-SQL
              UPDATE service_packs
              SET
              remained_units = remained_units -
                (SELECT SUM(t2.hours * t4.units_per_hour)
                FROM #{join_clause})
              , updated_at = CURRENT_TIMESTAMP()
              WHERE id = #{sp_to.id}
              SQL
    queries << <<-SQL
              UPDATE #{Assign.table_name}
              SET service_pack_id = #{sp_to.id},
              unassign_date = '#{sp_to.expired_date}'
              WHERE id = #{@assignment.id}
              SQL
    queries << <<-SQL
              UPDATE #{join_clause}
              SET t1.updated_at = CURRENT_TIMESTAMP(), t1.units = t2.hours * t4.units_per_hour,
              t1.service_pack_id = #{sp_to.id}
              WHERE t1.updated_at >= '#{assigned_time}';
              SQL
    # render plain: queries
    ActiveRecord::Base.transaction do
      queries.each do |sql| ActiveRecord::Base.connection.exec_query(sql) end
      flash[:success] = "Assignment successfully transferred to #{sp_to.name}"
    rescue
      flash[:alert] = -'One or both Service Packs might have been removed!'
    ensure
      redirect_to action: :show and return
    end
>>>>>>> Backend of transfer SP
  end

  def transferables
    if User.current.allowed_to?(:transfer_service_packs, @project)
      render plain: ServicePack.availables.to_json(except: [:threshold1, :threshold2, :updated_at, :created_at])
    else
      render plain: -'unauthorized', status: 403
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
    User.current.allowed_to?(:assign_service_packs, @project) ||
    User.current.allowed_to?(:unassign_service_packs, @project)
    
    start_day = params[:start_period]&.to_date # ruby >= 2.3.0
    end_day = params[:end_period]&.to_date
    if start_day.nil? ^ end_day.nil?
      render json: { error: 'GET OUT!'}, status: 400 and return
    end

    # Notice: Change max(t4.name) to ANY_VALUE(t4.name) on production builds.
    # MySQL specific >= 5.7.5
    # https://dev.mysql.com/doc/refman/5.7/en/group-by-handling.html

    get_parent_id = <<-SQL
      SELECT id, name, COALESCE(parent_id, id) AS pid
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
    par = start_day.nil? ? [query, @project.id] : [query, @project.id, start_day, end_day]
    sql = ActiveRecord::Base.send(:sanitize_sql_array, par)
    # render plain: sql
    render json: ActiveRecord::Base.connection.exec_query(sql).to_hash, status: 200
  end
end
