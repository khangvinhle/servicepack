class SpReportController < ApplicationController
  before_action :find_project_by_project_id, only: :proj_available
  include ServicePacksReportHelper

  def report
    # json & html endpoint
    # params[:service_pack, :start_date, :end_date]
    # binding.pry
    begin
      if params[:proj_id].present?
        raise ActiveRecord::RecordNotFound unless @project = Project.find_by(id: params[:proj_id])
      else
        @project = Project.find(params[:project_id])
      end
      spid = params[:service_pack_id]
      if spid.present?
        sp = ServicePack.find(spid)
      end
    rescue ActiveRecord::RecordNotFound
      render(status: 404) and return
    end

    unless User.current.allowed_to?(:see_assigned_service_packs, @project)
      render status: 404 and return
    end

    sql = query(service_pack: sp, project: @project,
                start_date: params[:start_date]&.to_date,
                end_date: params[:end_date]&.to_date)

    respond_to do |format|
      format.html {
        # change this to debug
        # render plain: sp_available
        get_projects_available
        get_available_service_packs
        render -'show'
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
    render json: { projects: get_projects_available.pluck(:id, :name), preselect: @project.id }
  end

  def sp_available
    render json: { projects: get_available_service_packs, preselect: nil } # just use the first one
  end

  private

    def get_projects_available
      @projects ||= Project.allowed_to(User.current, :see_assigned_service_packs)
    end

    def get_available_service_packs
      @sps ||=  if User.current.admin?
                 ServicePack.all.pluck(:id, :name)
                else
                  Assign.active.joins(:service_pack)
                   .where(project_id: get_projects_available.pluck(:id))
                   .pluck(-'service_packs.id', -'service_packs.name')
                end
    end
end