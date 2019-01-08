class ServicePacksController < ApplicationController
  # only allow admin
  before_action :require_admin

  # Specifying Layouts for Controllers, looking at OPENPROJECT_ROOT/app/views/layouts/admin
  layout 'admin'

  def index
    @sp = ServicePack.all
  end

  def show
    @sp = ServicePack.find(params[:id])
  end

  def new
    @sp = ServicePack.new
  end

  def edit
    @sp = ServicePack.find(params[:id])
  end

  def update
    @sp = ServicePack.find(params[:id])
    if @sp.update(params.require(:service_pack).permit(:name, :threshold1, :threshold2, :management, :specification, :development, :other, :testing, :support))
      redirect_to @sp
    else
      render 'edit'
    end

  end

  def create
    @sp = ServicePack.new(permitted_params)
    if @sp.save
      redirect_to @sp
    else
      render 'new'
    end

  end

  private

  def permitted_params
    params.require(:service_pack).permit(:name, :total_units, :start_date, :expired_date, :threshold1, :threshold2, :management, :development, :specification, :other, :testing, :support)
  end
end
