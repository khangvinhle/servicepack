module CsvExtractionHelper
	def csv_extractor(entries)
		# from timelog_helper.rb
		# decimal_separator = l(:general_csv_decimal_separator) # not needed
		# custom_fields = TimeEntryCustomField.all # not supported
		export = CSV.generate(col_sep: l(:general_csv_separator)) { |csv|
			headers = ['Date', 'User', 'Activity', 'Project', 'Work Package', 'Type', 'Subject', 'Units', 'Comments']
			# headers += custom_fields.map(&:name) # not supported
			csv << headers
      		entries.each do |entry|
      			fields = [format_date(entry['spent_on']),
      				entry['user_name'],
      				entry['activity_name'],
      				entry['project_name'],
      				entry['work_package_id'],
      				entry['type_name'],
      				entry['subject'],
      				entry['units'],
      				entry['comment']
      			]
      			# fields += custom_fields.map { |f| show_value(entry.custom_value_for(f)) }
                        # binding.pry
      			csv << fields
      		end

      	}
            export
	end
end