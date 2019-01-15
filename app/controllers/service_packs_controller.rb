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
    TimeEntryActivity.shared.count.times {@service_pack.mapping_rates.build}
  end

  def show
    @service_pack = ServicePack.find(params[:id])
    @rates = @service_pack.mapping_rates
  end

  def create
    @service_pack = ServicePack.new(service_pack_params)
    if @service_pack.save
      redirect_to @service_pack
    else
      render 'new'
    end
  end

  private

  def service_pack_params
    params.require(:service_pack).permit(:name, :total_units, :started_date, :expired_date, :threshold1, :threshold2, mapping_rates_attributes: [:id, :activity_id, :service_pack_id, :units_per_hour])
  end

end
