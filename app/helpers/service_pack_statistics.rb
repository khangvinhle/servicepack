class ServicePackStatistics
	# waiting for schema
	# acceptance day: 80h left
	def analyze_by_activity(service_pack=nil)
		q = <<-SQL
			select sum(units)
			from #{ServicePackEntry.table_name}
			
			SQL
	end

	def query_executor(service_pack=nil, begin_period=nil, begin_post_period=nil)

	end
end