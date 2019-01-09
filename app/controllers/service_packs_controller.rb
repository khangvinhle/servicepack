class ServicePacksController < ApplicationController

	# only allow admin
	before_action :require_admin

	# Specifying Layouts for Controllers, looking at OPENPROJECT_ROOT/app/views/layouts/admin
	layout 'admin'
	
	def index
	end

	def new
	end

	def show
		@service_pack = ServicePack.find(params[:id])
	end

end
