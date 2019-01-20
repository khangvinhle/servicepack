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
    # add some json between this
    # controller chooses not to get the thresholds.
    # assume the service pack exists.
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
