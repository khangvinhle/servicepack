module ServicePacksReportHelper
  def query(service_pack: nil, project: nil, start_date: nil, end_date: nil, order_by: :created, **options)
    # binding.pry
    proj_clause = <<-SQL
                  SELECT t2.spent_on AS log_date, t1.created_at AS spent_on,
                  concat(t4.firstname, ' ', t4.lastname) AS user_name, 
                  t3.name AS activity_name, t5.id AS work_package_id, t5.subject AS subject,
                  t1.units AS units, t2.hours AS hours, t6.name AS type_name
                  SQL
    proj_clause << -', t2.comments AS comment' unless options[:lite]
    query_to_sanitize = [proj_clause] # note that this array only store copy of a pointer to object...
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
    where_clause << " AND t1.created_at >= '#{start_date}' " if start_date
    where_clause << " AND t1.created_at < '#{end_date.next}' " if end_date

    if project&.id # project given?
      # specific project
      where_clause << " AND t2.project_id = #{project.id} "
      proj_clause << -', ? AS project_name '
      query_to_sanitize << project.name
    else
      # all project
      where_clause << " AND t2.#{get_where_clause_fragment(get_projects_available)}" unless User.current.admin?
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
    # ... that's why we append
    proj_clause << "#{from_clause} #{where_clause} ORDER BY #{order_by == :date ? -'log_date' : -'spent_on'} DESC"

    sql = ActiveRecord::Base.send(:sanitize_sql_array, query_to_sanitize)

    @entries = ActiveRecord::Base.connection.exec_query(sql)

  rescue
    raise -'Query failed'
  end

  def csv_extractor(entries: @entries, using_excel: true)
    raise -'Query not run yet' unless entries
    decimal_separator = I18n.t(:general_csv_decimal_separator)
    flag = decimal_separator.blank? || decimal_separator == -'.'
    csv_lambda = lambda { |csv|
      headers = [-'Created', -'Date', -'User', -'Activity', -'Project', -'Work Package', -'Hours', -'Type',
                 -'Subject', -'Service Pack', -'Units', -'Comments']
      # headers += custom_fields.map(&:name) # not supported
      # round() is Ruby >= 2.5
      csv << headers
      entries.each do |entry|
        fields = [entry[-'spent_on'],
                  entry[-'log_date'],
                  entry[-'user_name'],
                  entry[-'activity_name'],
                  entry[-'project_name'],
                  entry[-'work_package_id'],
                  flag ? entry[-'hours'].round(2) : entry[-'hours'].round(2).to_s.gsub(-'.', decimal_separator),
                  entry[-'type_name'],
                  entry[-'subject'],
                  entry[-'sp_name'], # new field added
                  flag ? entry[-'units'].round(2) : entry[-'units'].round(2).to_s.gsub(-'.', decimal_separator),
                  entry[-'comment']
                 ]
        # fields += custom_fields.map { |f| show_value(entry.custom_value_for(f)) }
        csv << fields
      end
    }
    export = using_excel ? CSV.generate(col_sep: -';', headers: -'sep=;', write_headers: true, &csv_lambda) :
                           CSV.generate(col_sep: -';', &csv_lambda)
  end

  def get_projects_available
    @projects ||= User.current.admin? ? Project.all : Project.allowed_to(User.current, :see_assigned_service_packs)
  end

  def get_available_service_packs
    @sps ||=  if User.current.admin?
                ServicePack.all.pluck(:id, :name)
              else
                Assign.active.joins(:service_pack)
                .where("assigns.project_id IN (#{get_projects_available.select(:id).to_sql})")
                .pluck(-'service_packs.id', -'service_packs.name')
              end
  end

  private
    def get_where_clause_fragment(projects)
      # applicable for query all projects
      if projects is_a? ActiveRecord::Relation
        "project_id IN (#{projects.select(:id).to_sql})"
      elsif projects is_a? Project
        "project_id = #{projects.id}"
      else
        raise ArgumentError, -'must be Project or AR-R'
      end
    end
end