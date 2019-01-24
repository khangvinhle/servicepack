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
        render plain: ServicePackPresenter.new(@service_pack).json_export(:rate)
      }
      format.html {
        @rates = @service_pack.mapping_rates
        @assignments = @service_pack.assigns.where(assigned: true).all
      }
    end
  end

  def create
    # @service_pack = ServicePack.new(service_pack_params)
    # if @service_pack.save
    #   redirect_to @service_pack
    # else
    #   render 'new'
    # end
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
        flash.now[:error] = 'Service Pack creation failed.'
        @service_pack = ServicePack.new
        render 'new'
      end
    else
      # render plain: 'duplicated'
      flash.now[:error] = 'Only one rate can be defined to one activity.'
      @service_pack = ServicePack.new
      render 'new'
    end
  end

  def edit
    @sp = ServicePack.find(params[:id])
    @activity = @sp.time_entry_activities.build
  end

  def destroy
    @sp = ServicePack.find(params[:id])
    @sp.destroy

    redirect_to service_packs_path
  end

  def statistics
    get_parent_id = <<-SQL
      SELECT id, name,
      CASE parent_id WHEN NULL THEN id ELSE parent_id AS pid
      FROM #{TimeEntryActivity.table_name}
      SQL
    body_query = <<-SQL
      SELECT t3.pid AS pid, t3.name AS name, sum(t1.units) AS consumed
      FROM #{ServicePackEntry.table_name} t1
      INNER JOIN #{TimeEntry.table_name} t2
      ON t1.time_entry_id = t2.id
      INNER JOIN (#{get_parent_id}) t3
      ON t2.activity_id = t3.pid AND t3.type = 'TimeEntryActivity'
      SQL
    group_clause = <<-SQL
      GROUP BY t3.pid, t3.name
      ORDER BY consumed
      SQL
    # render plain: body_query + group_clause

    start_day = params[:start_period]&.to_date # ruby >= 2.3.0
    end_day = params[:end_period]&.to_date
    if start_day.nil? ^ end_day.nil?
      render json: { error: 'GET OUT!'}, status: 400 and return
    end
    where_clause = "WHERE t1.service_pack_id = ?"
    where_clause << (start_day.nil? ? '' : ' AND t2.created_at BETWEEN ? AND ?')
    render plain: body_query + where_clause + group_clause
  end

  private

  def service_pack_params
    params.require(:service_pack).permit(:name, :total_units, :started_date, :expired_date, :threshold1, :threshold2, mapping_rates_attributes: [:id, :activity_id, :service_pack_id, :units_per_hour, :_destroy])
  end

end
