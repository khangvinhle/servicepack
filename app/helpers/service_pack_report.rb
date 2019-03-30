class ServicePackReport
	attr_reader :service_pack

	def initialize(service_pack)
		if service_pack&.id
			@service_pack = service_pack
		else
			raise -'This service pack is NIL, cannot report'
		end
	end

	def query(project = nil)
		sql = <<-SQL
          SELECT t2.spent_on, concat(t4.firstname, ' ', t4.lastname) AS user_name, t3.name AS activity_name,
			    t5.id AS work_package_id, t7.name AS type_name, t5.subject AS subject, t2.comments AS comment,
          t1.units AS units, t2.hours AS hours, #{project.nil? ? 't6.name' : "'#{project.name}'"} AS project_name
          FROM service_pack_entries t1
          INNER JOIN #{TimeEntry.table_name} t2
          ON t1.time_entry_id = t2.id
          INNER JOIN #{TimeEntryActivity.table_name} t3
          ON t2.activity_id = t3.id
          INNER JOIN users t4
          ON t2.user_id = t4.id
          #{project.nil? ? 'INNER JOIN projects t6 ON t2.project_id = t6.id' : ''}
          LEFT JOIN #{WorkPackage.table_name} t5
          ON t2.work_package_id = t5.id
          LEFT JOIN types t7
          ON t5.type_id = t7.id
          WHERE service_pack_id = #{@service_pack.id}
          #{project.nil? ? '' : "AND t2.project_id = #{project.id}"}
          ORDER BY spent_on DESC
          SQL
    @entries = ActiveRecord::Base.connection.exec_query(sql).to_hash
  end

  def csv_extractor
    raise -'Query not run yet' unless @entries
    decimal_separator = I18n.t(:general_csv_decimal_separator)
    export = CSV.generate(col_sep: ';') { |csv|
      headers = [-'Date', -'User', -'Activity', -'Project', -'Work Package', -'Hours', -'Type', -'Subject', -'Units', -'Comments']
  		# headers += custom_fields.map(&:name) # not supported
  		csv << headers
      @entries.each do |entry|
        fields = [entry[-'spent_on'],
                  entry[-'user_name'],
                  entry[-'activity_name'],
                  entry[-'project_name'],
                  entry[-'work_package_id'],
                  entry[-'hours'].round(2).to_s.gsub(-'.', decimal_separator),
                  entry[-'type_name'],
                  entry[-'subject'],
                  entry[-'units'].round(0),
                  entry[-'comment']
                 ]
        # fields += custom_fields.map { |f| show_value(entry.custom_value_for(f)) }
        csv << fields
      end
    }
  end

  def call(project=nil)
    self.query(project)
    self.csv_extractor
  end
end