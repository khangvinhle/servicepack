class ServicePacksController < ApplicationController
  # only allow admin
  before_action :require_admin

  # Specifying Layouts for Controllers, looking at OPENPROJECT_ROOT/app/views/layouts/admin
  layout 'admin'

  def index
    @service_packs = ServicePack.all
  end

  def new
    @service_pack = ServicePack.new
    # TimeEntryActivity.shared.count.times {@service_pack.mapping_rates.build}
    @sh = TimeEntryActivity.shared
    @c = TimeEntryActivity.shared.count
  end

  def show
    @service_pack = ServicePack.find(params[:id])
    # controller chooses not to get the thresholds.
    # assume the service pack exists.
    # TODO: make a separate action JSON only.
    respond_to do |format|
      format.json {
        # the function already converted this to json
        render plain: ServicePackPresenter.new(@service_pack).json_export(:rate), status: 200
      }
      format.html {
        @rates = @service_pack.mapping_rates
        @assignments = @service_pack.assigns.where(assigned: true).all
        # exs = ExpiredSpMailer.new # never instantiate
        # binding.pry
        # ExpiredSpMailer.expired_email(User.last, @service_pack).deliver_now
      }
    end
  end

  def create
    mapping_rate_attribute = params['service_pack']['mapping_rates_attributes']
    # binding.pry
    activity_id = []
    mapping_rate_attribute.each {|_index, hash_value| activity_id.push(hash_value['activity_id'])}

    if activity_id.uniq.length == activity_id.length
      @service_pack = ServicePack.new(service_pack_params)
      # render plain: 'not duplicated'
      if @service_pack.save
        flash[:notice] = 'Service Pack creation successful.'
        redirect_to action: :show, id: @service_pack.id and return
      else
        flash[:error] = 'Service Pack creation failed.'
        redirect_to action: :new
      end
    else
      # render plain: 'duplicated'
      flash[:error] = 'Only one rate can be defined to one activity.'
      redirect_to action: :new
    end
  end

  def edit
    @sp = ServicePack.find_by(id: params[:id])
    if @sp.nil?
      flash[:error] = "Service Pack not found"
      redirect_to action: :index and return
    end
    @activity = @sp.time_entry_activities.build
  end

  def update
    @sp = ServicePack.find_by(id: params[:id])
    if @sp.nil?
      flash[:error] = "Service Pack not found"
      redirect_to action: :index and return
    end
    mapping_rate_attribute = params['service_pack']['mapping_rates_attributes']
    activity_id = []
    mapping_rate_attribute.each {|_index, hash_value| activity_id.push(hash_value['activity_id'])}

    if activity_id.uniq.length == activity_id.length
      @sp.update(service_pack_params)
      # render plain: 'not duplicated'
      if @sp.save
        flash[:notice] = 'Service Pack update successful.'
        redirect_to action: :show, id: @sp.id and return
      else
        flash.now[:error] = 'Service Pack update failed.'
        @activity = @sp.time_entry_activities.build
        render 'edit'
      end
    else
      # render plain: 'duplicated'
      flash.now[:error] = 'Only one rate can be defined to one activity.'
      @activity = @sp.time_entry_activities.build
      renders 'edit'
    end
  end

  def destroy
    @sp = ServicePack.find_by(params[:id])
    if @sp.nil?
      flash[:error] = "Service Pack not found"
      redirect_to action: :index and return
    end
    if @sp.assigned?
      flash[:error] = "Please unassign this SP from all projects before proceeding!"
      redirect_to action: :show, id: @sp.id and return
    end
    @sp.destroy!

    redirect_to service_packs_path
  end


  # =======================================================
  # :Docs
  # * Limit: Serving JSON only. Must be Admin to access.
  # * Purpose:
  # Return a table with consumed units for a Service Pack grouped by activities and sorted
  # from large to small.
  # * Expected Inputs:
  # [service_pack_id]: Sharing the same route with the resourceful default.
  # Put in the link. Mandatory.
  # [start_period]: Beginning of the counting period. As a date. Optional.
  # [end_period]: Ending of the counting period. As a date. Optional.
  # start_period MUST NOT be later than end_period.
  # Both or none of [start_period, end_period] can be present.
  # * Expected Outputs
  # Top class: None
  # Content: Array of object having [name, consumed]
  # - consumed: How many units are consumed (in given period)
  # - act_name: Name of activity 
  # Status: 200
  # * When raising error
  # HTTP 404: SP not found
  # HTTP 400: Malformed request.
  # =======================================================

  def statistics
    start_day = params[:start_period]&.to_date # ruby >= 2.3.0
    end_day = params[:end_period]&.to_date
    if start_day.nil? ^ end_day.nil?
      render json: { error: 'GET OUT!'}, status: 400 and return
    end

    if !ServicePack.find_by(id: params[:service_pack_id])
      render json: { error: 'NOT FOUND'}, status: 404 and return
    end

    # Notice: Change max(t3.name) to ANY_VALUE(t3.name) on production builds.
    # MySQL specific >= 5.7.5
    # https://dev.mysql.com/doc/refman/5.7/en/group-by-handling.html

    get_parent_id = <<-SQL
      SELECT id, name,
      CASE WHEN parent_id IS NULL THEN id ELSE parent_id END AS pid
      FROM #{TimeEntryActivity.table_name}
      WHERE type = 'TimeEntryActivity'
      SQL
    body_query = <<-SQL
      SELECT t3.pid AS act_id, max(t3.name) AS act_name, sum(t1.units) AS consumed
      FROM #{ServicePackEntry.table_name} t1
      INNER JOIN #{TimeEntry.table_name} t2
      ON t1.time_entry_id = t2.id
      INNER JOIN (#{get_parent_id}) t3
      ON t2.activity_id = t3.id
      SQL
    group_clause = <<-SQL
      GROUP BY t3.pid
      ORDER BY consumed DESC
      SQL
    where_clause = "WHERE t1.service_pack_id = ?"
    where_clause << (start_day.nil? ? '' : ' AND t1.created_at BETWEEN ? AND ?')
    query = body_query + where_clause + group_clause
    # binding.pry
    par = start_day.nil? ? [query, params[:service_pack_id]] : [query, params[:service_pack_id], start_day, end_day]
    sql = ActiveRecord::Base.send(:sanitize_sql_array, par)
    render json: ActiveRecord::Base.connection.exec_query(sql).to_hash, status: 200
  end

  private

  def service_pack_params
    params.require(:service_pack).permit(:name, :total_units, :started_date, :expired_date, :threshold1, :threshold2, 
      mapping_rates_attributes: [:id, :activity_id, :service_pack_id, :units_per_hour, :_destroy])
  end

end
