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
		TimeEntryActivity.count.times { @service_pack.mapping_rates.build }
	end

	def show
		@service_pack = ServicePack.find(params[:id])
	end

	def create
		@service_pack = ServicePack.new(service_pack_params)

		@service_pack.default_remained_units

		if @service_pack.save
			redirect_to @service_pack
		else
			render 'new'
		end
	end

	private 
		def service_pack_params
			params.require(:service_pack).permit(:name, :total_units, :started_date, :expired_date, :threshold1, :threshold2)
		end

end
