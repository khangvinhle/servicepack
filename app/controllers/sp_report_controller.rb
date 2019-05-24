class SpReportController < ApplicationController
  before_action :find_project_by_project_id, only: :report
  include ServicePacksReportHelper

  NUMBER_OF_FILLED_COLUMN = 9

  def report
    begin
      set_by_filter_proj_id = params[:proj_id]
      unless set_by_filter_proj_id == -'all'
        if set_by_filter_proj_id.present?
          @project_to_report = Project.find_by!(id: set_by_filter_proj_id)
        else
          @project_to_report = @project # used by OpenProject for layout
        end
        unless User.current.admin? || User.current.allowed_to?(:see_assigned_service_packs, @project_to_report)
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
        query(service_pack: sp, project: @project_to_report,
              lite: true)
        get_projects_available
        get_available_service_packs
        render -'show' and return
      }
      format.json {
        query(service_pack: sp, project: @project_to_report,
              lite: true)
        render json: @entries
      }
      format.csv {
        query(service_pack: sp, project: @project_to_report)
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