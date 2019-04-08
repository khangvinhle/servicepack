class SpReportController < ApplicationController
  before_action :find_project_by_project_id
  include ServicePacksReportHelper

  def report
    # json & html endpoint
    # params[:service_pack, :start_date, :end_date]
    spid = params[:service_pack_id]
    if spid.present?
      @fault = true and render_404 unless sp = ServicePack.find_by(id: spid)
    end
    sql = query(service_pack: sp, project: @project,
                start_date: params[:start_date]&.to_date,
                end_date: params[:end_date]&.to_date)

    respond_to do |format|
      format.html {
        # change this to debug
        render plain: sp_available
      }
      format.json {
        render json: @entries
      }
      format.csv {
        # todo
      }
    end
  end

  def proj_available
    get_projects_available.pluck(:id, :name)
  end

  def sp_available
    Assign.active.joins(:service_pack)
                  .where(project_id: get_projects_available.pluck(:id))
                  .pluck(-'service_packs.id', 'service_packs.name')
  end

  private

    def get_projects_available
      @projects ||= Project.allowed_to(User.current, :see_assigned_service_packs)
    end
end