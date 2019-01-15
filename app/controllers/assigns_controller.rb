class AssignsController < ApplicationController
	layout 'admin'
	before_action :require_admin, :find_project_by_project_id

	def assign
=begin
		if !@project.module_enabled?(:openproject_service_packs)
			render_400 and return
		end
=end
		pry.binding
		# require 'pry-nav'
		if !(@project.assigns.where(assigned: true).empty?)
			flash[:alert] = "You must unassign first!"
			render_400 and return
		end
		@service_pack = ServicePack.find(params[:service_pack_id])
		pry.binding
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
				flash[:success] = "Service Pack #{@service_pack.name} successfully assigned to project #{@project.name}"
				redirect_to action: "show" and return
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
		if !@project.module_enabled?(:openproject_service_packs)
			render_400 and return
		end
		@assignment = @project.assigns.find_by(assigned: true)
		if @assignment.nil?
			flash[:alert] = "No Service Pack is assigned to this project"
			render_404 and return
		end
		@assignment.assigned = false
		@assignment.save!
		flash[:success] = "Unassigned a Service Pack from this project"
		redirect_to action: "show"
	end
	
	def show
=begin
		if !@project.module_enabled?(:openproject_service_packs)
			render_400 and return
		end
=end


		# assigned now
		@assignment = @project.assigns.find_by(assigned: true)
		if @assignment && @assignment.service_pack.unavailable?
			@assignment.assigned = false
			@assignment.save!
			@assignment = nil # overdue
		end
		#binding.pry
		if @assignment.nil?
			# testing only
			t = ServicePack.where("expired_date >= ?", Date.today)
			#binding.pry
			@assignables = []
			t.each do |assignable|
				if assignable.assigns.empty?
					@assignables << assignable
				end
			end
			#binding.pry
		else
			@sp = @assignment.service_pack
		end
	end
end
