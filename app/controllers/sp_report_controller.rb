class SpReportController < ApplicationController
  before_action :find_project_by_project_id, only: :proj_available
  include ServicePacksReportHelper

  NUMBER_OF_FILLED_COLUMN = 9

  def report
    begin
      set_by_filter_proj_id = params[:proj_id]
      unless set_by_filter_proj_id == -'all'
        if set_by_filter_proj_id.present?
          @project = Project.find_by!(id: set_by_filter_proj_id)
        else
          @project = Project.find(params[:project_id]) # find by slug
        end
        unless User.current.admin? || User.current.allowed_to?(:see_assigned_service_packs, @project)
          render status: 404 and return
        end
      end
      spid = params[:service_pack_id]
      sp = ServicePack.find(spid) if spid.present?
    rescue ActiveRecord::RecordNotFound
      render status: 404 and return
    end

    respond_to do |format|
      # @project will be nil if "all" choice is on bypassing the "unless set_by_filter_proj_id" block
      format.html {
        query(service_pack: sp, project: @project,
              lite: true)
        get_projects_available
        get_available_service_packs
        render -'show' and return
      }
      format.json {
        query(service_pack: sp, project: @project,
              lite: true)
        render json: @entries
      }
      format.csv {
        query(service_pack: sp, project: @project)
        render csv: csv_extractor, filename: "sp-report-#{Date.today}.csv" and return
      }
    end
  end

  def proj_available
    render json: { projects: get_projects_available.pluck(:id, :name), preselect: @project.id }
  end

  def sp_available
    render json: { service_packs: get_available_service_packs, preselect: nil } # just use the first one
  end

end