module ServicePacksReportHelper
  def query(service_pack: nil, project: nil, start_date: nil, end_date: nil)
    # binding.pry
    proj_clause = <<-SQL
                  SELECT t1.created_at AS spent_on, concat(t4.firstname, ' ', t4.lastname) AS user_name, 
                  t3.name AS activity_name, t5.id AS work_package_id, t5.subject AS subject,
                  t2.comments AS comment, t1.units AS units, t2.hours AS hours, t6.name AS type_name
                  SQL
    query_to_sanitize = [proj_clause]
    from_clause = <<-SQL
                  FROM service_pack_entries t1
                  LEFT JOIN #{TimeEntry.table_name} t2
                  ON t1.time_entry_id = t2.id
                  INNER JOIN #{TimeEntryActivity.table_name} t3
                  ON t2.activity_id = t3.id
                  INNER JOIN users t4
                  ON t2.user_id = t4.id
                  LEFT JOIN #{WorkPackage.table_name} t5
                  ON t2.work_package_id = t5.id
                  LEFT JOIN types t6
                  ON t5.type_id = t6.id
                  SQL

    where_clause = 'WHERE 1 = 1'
    dts = start_date&.to_s
    ets = (end_date&.next_day)&.to_s
    where_clause << " AND t1.created_at >= '#{dts}' " if dts
    where_clause << " AND t1.created_at < '#{ets}' " if ets

    if project&.id # project given?
      # specific project
      where_clause << " AND t2.project_id = #{project.id} "
      proj_clause << -', ? AS project_name '
      query_to_sanitize << project.name
    else
      # all project
      from_clause << -' INNER JOIN projects t7 ON t2.project_id = t7.id '
      proj_clause << -', t7.name AS project_name '
    end

    if service_pack&.id # SP given?
      # specific SP
      where_clause << " AND t1.service_pack_id = #{service_pack.id} "
      proj_clause << -', ? AS sp_name '
      query_to_sanitize << service_pack.name
    else
      # all SP
      from_clause << -' INNER JOIN service_packs t8 ON t1.service_pack_id = t8.id '
      proj_clause << -', t8.name AS sp_name'
    end
    proj_clause << from_clause << where_clause
    proj_clause << -' ORDER BY spent_on DESC '

    sql = ActiveRecord::Base.send(:sanitize_sql_array, query_to_sanitize)

    @entries = ActiveRecord::Base.connection.exec_query(sql)
    sql
  end

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