class AssignsController < ApplicationController
	layout 'admin'
	before_action :require_admin, :find_project_by_project_id

	def assign
		if !@project.module_enabled?(:service_packs)
			render_400 and return
		end
		if @project.assigns.where(assigned: true)
			flash[:now] = "You must unassign first!"
			return
		end
		@service_pack = ServicePack.find(params[:service_pack])
		if @service_pack.available?
			if assignable = !(@service_pack.assigns.where(assigned: true))
				ActiveRecord::Base.transaction do
					@project.assigns.update_all!(assigned: false)
					if @assign_record = ServicePack.assigns.where(project_id: @project.id) || @project.assigns.new
						@assign_record.assigned = true
						@assign_record.service_pack_id = params[:service_pack]
						@assign_record.save!					
					end
				end
				return
			else
				# already assigned
				flash[:now] = "Service Pack #{@service_pack.name} has been already assigned"
				render_400 and return
			end
		end
		flash[:now] = "Service Pack not found"
		render_400
	end

	def unassign

	end
	def show
		if !@project.module_enabled?(:service_packs)
			render_502 and return
		end
		# assigned now

		# possible to assign
	end
end
