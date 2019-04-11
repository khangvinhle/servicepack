class ServicePacksController < ApplicationController
  # only allow admin
  before_action :require_admin
  include ServicePacksReportHelper

  # Specifying Layouts for Controllers, looking at OPENPROJECT_ROOT/app/views/layouts/admin
  layout 'admin'

  def index
    @service_packs = ServicePack.all
    # for demo
    #ServicePacksMailer.notify_under_threshold1(User.first,@service_packs.first).deliver_now
  end

  def new
    @service_pack = ServicePack.new
    # TimeEntryActivity.shared.count.times {@service_pack.mapping_rates.build}
    @sh = TimeEntryActivity.shared
    @c = @sh.count
  end

  def show
    @service_pack = ServicePack.find(params[:id])
    # controller chooses not to get the thresholds.
    # assume the service pack exists.
    # TODO: make a separate action JSON only.
    binding.pry
    respond_to do |format|
      format.json {
        # the function already converted this to json
        render plain: ServicePackPresenter.new(@service_pack).json_export(:rate), status: 200
      }
      format.html {
        # http://www.chrisrolle.com/en/blog/benchmark-preload-vs-eager_load
        @rates = @service_pack.mapping_rates.preload(:activity)
        @assignments = @service_pack.assignments.preload(:project)
      }
      format.csv {
        render csv: csv_extractor(query(service_pack: @service_pack)), filename: "service_pack_#{@service_pack.name}.csv"
      }
    end
  end

  # The string with the minus sign in front is a shorthand for <string>.freeze
  # reducing server processing time (and testing time) by 30%!
  # Freezing a string literal will stop it from being created anew over and over.
  # All literal strings will be frozen in Ruby 3 by default, which is a good idea.

  def create
    mapping_rate_attribute = params[:service_pack][:mapping_rates_attributes]
    # binding.pry
    activity_id = []
    mapping_rate_attribute.each {|_index, hash_value| activity_id.push(hash_value[:activity_id])}

    if activity_id.uniq.length == activity_id.length
      @service_pack = ServicePack.new(service_pack_params)
      # render plain: 'not duplicated'
      if @service_pack.save
        flash[:notice] = -'Service Pack creation successful.'
        redirect_to action: :show, id: @service_pack.id and return
      else
        flash.now[:error] = -'Service Pack creation failed.'
      end
    else
      # render plain: 'duplicated'
      flash.now[:error] = -'Only one rate can be defined to one activity.'
    end
    # the only successful path has returned 10 lines ago.
    @sh = TimeEntryActivity.shared
    @c = TimeEntryActivity.shared.count
    render 'new'
  end

  def edit
    @sp = ServicePack.find_by(id: params[:id])
    if @sp.nil?
      flash[:error] = -"Service Pack not found"
      redirect_to action: :index and return
    end
    # @activity = @sp.time_entry_activities.build
  end

  def update
    @sp = ServicePack.find_by(id: params[:id])
    if @sp.nil?
      flash[:error] = -"Service Pack not found"
      redirect_to action: :index and return
    end
    mapping_rate_attribute = params[:service_pack][:mapping_rates_attributes]
    activity_id = []
    mapping_rate_attribute.each {|_index, hash_value| activity_id.push(hash_value[:activity_id])}

    if activity_id.uniq.length == activity_id.length
      # No duplication
      add_units
      @sp.assign_attributes(service_pack_edit_params)
      # binding.pry
      if @sp.save
        flash[:notice] = -'Service Pack update successful.'
        redirect_to @sp
      else
        flash.now[:error] = -'Service Pack update failed.'
        render -'edit'
      end
    else
      # Duplication
      flash.now[:error] = -'Only one rate can be defined to one activity.'
      render -'edit'
    end
  end

  def destroy
    @sp = ServicePack.find_by(id: params[:id])
    if @sp.nil?
      flash[:error] = -"Service Pack not found"
      redirect_to action: :index and return
    end
    if @sp.assigned?
      flash.now[:error] = "Please unassign this SP from all projects before proceeding!"
      redirect_to @sp
    end
    @sp.destroy!

    redirect_to service_packs_path
  end

  # for breadcrumb code
  def show_local_breadcrumb
    true
  end

  def default_breadcrumb
    action_name == 'index'? -'Service Packs' : ActionController::Base.helpers.link_to(-'Service Packs', service_packs_path)
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
      render json: {error: 'GET OUT!'}, status: 400 and return
    end
    if !ServicePack.find_by(id: params[:service_pack_id])
      render json: {error: 'NOT FOUND'}, status: 404 and return
    end

    # Notice: Change max(t3.name) to ANY_VALUE(t3.name) on production builds.
    # MySQL specific >= 5.7.5
    # https://dev.mysql.com/doc/refman/5.7/en/group-by-handling.html

    get_parent_id = <<-SQL
      SELECT id, name, COALESCE(parent_id, id) AS pid
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

  def service_pack_edit_params
    params.require(:service_pack).permit(:threshold1, :threshold2,
                                        mapping_rates_attributes: [:id, :activity_id, :service_pack_id, :units_per_hour, :_destroy])
  end

  def add_units
    return unless params[:service_pack][:total_units]
    if (t = params[:service_pack][:total_units].to_f) <= 0.0
      @sp.errors.add(:total_units, 'is invalid') and return
    end
    @sp.grant(t - @sp.total_units) unless t == @sp.total_units
  end

end
