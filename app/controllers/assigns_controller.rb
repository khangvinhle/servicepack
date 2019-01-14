class AssignsController < ApplicationController
	layout 'admin'
	before_action :require_admin, :find_project_by_project_id

	def assign
		if !@project.module_enabled?(:service_packs)
			render_400 and return
		end
		if !(@project.assigns.where(assigned: true).empty?)
			flash[:alert] = "You must unassign first!"
			return
		end
		@service_pack = ServicePack.find(params[:service_pack])
		if @service_pack.available?
			if assignable = @service_pack.assigns.where(assigned: true).empty?
				ActiveRecord::Base.transaction do
					# one query only
					@project.assigns.update_all!(assigned: false)
					@assign_record = ServicePack.assigns.find_by(project_id: @project.id) || @project.assigns.new
					@assign_record.assigned = true
					@assign_record.service_pack_id = params[:service_pack_id]
					@assign_record.save!
				end
				return
			else
				# already assigned for another project
				flash[:alert] = "Service Pack #{@service_pack.name} has been already assigned"
				render_400 and return
			end
		end
		flash[:alert] = "Service Pack not found"
		render_404
	end

	def unassign
		if !@project.module_enabled?(:service_packs)
			render_400 and return
		end
		@assignment = @project.assigns.find_by(assigned: true)
		if @assignment.nil?
			flash[:alert] = "No ServicePack is assigned to this project"
			render_404 and return
		end
		@assignment.assigned = false
		@assignment.save!
		# plan to redirect user.
	end
	
	def show
		if !@project.module_enabled?(:service_packs)
			render_400 and return
		end
		# assigned now
		@assignment = @project.assigns.find_by(assigned: true)
		if @assignment && @assignment.service_pack.unavailable?
			@assignment.assigned = false
			@assignment.save!
			@assignment = nil # overdue
		end
		# possible to assign
		@assignables = ServicePacks.where("expire_date < ?", Date.today).assigns.exists.not(assigned: true)
	end
end
