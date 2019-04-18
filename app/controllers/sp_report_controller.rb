class SpReportController < ApplicationController
  before_action :find_project_by_project_id, only: :proj_available
  include ServicePacksReportHelper

  NUMBER_OF_FILLED_COLUMN = 7

  def report
    # json & html endpoint
    # params[:service_pack, :start_date, :end_date]
    # binding.pry
    begin
      if params[:proj_id].present?
        @project = Project.find_by!(id: params[:proj_id])
      else
        @project = Project.find(params[:project_id]) # find by slug
      end
      spid = params[:service_pack_id]
      if spid.present?
        sp = ServicePack.find(spid)
      end
    rescue ActiveRecord::RecordNotFound
      render(status: 404) and return
    end

    unless User.current.admin? || User.current.allowed_to?(:see_assigned_service_packs, @project)
      render status: 404 and return
    end

    respond_to do |format|
      format.html {
        # change this to debug
        # render plain: sp_available
        query(service_pack: sp, project: @project,
              lite: true)
        get_projects_available
        get_available_service_packs
        render -'show'
      }
      format.json {
        query(service_pack: sp, project: @project,
              lite: true)
        render json: @entries
      }
      format.csv {
        query(service_pack: sp, project: @project)
        render csv: csv_extractor(@entries), filename: "sp-report-#{Date.today}.csv"
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