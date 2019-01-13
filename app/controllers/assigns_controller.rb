class AssignsController < ApplicationController
	layout 'admin'
	before_action :require_admin, :find_project_by_project_id
	def new
		#Not Implemented Yet - find hooks first
	end
end
