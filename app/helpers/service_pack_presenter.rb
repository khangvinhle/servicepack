class ServicePackPresenter
	attr_reader :service_pack
	def initialize(service_pack)
		# we don't take NIL as an option
		if service_pack&.id
			@service_pack = service_pack
		else
			raise 'This is NIL cannot print'
		end
	end
	def json_full_header
		# not recommended in production
		@service_pack.to_json
	end
	def hash_lite_header
		@service_pack.as_json(except: [:id, :threshold1, :threshold2, :updated_at, :created_at])
	end
	def json_lite_header
		hash_lite_header.to_json
	end
	def hash_rate_only
		# ActiveRecord join returns an array!
		q = <<-SQL
			SELECT name, units_per_hour AS upt
			FROM mapping_rates t1
			INNER JOIN #{TimeEntryActivity.table_name} t2
			ON t1.activity_id = t2.id
			WHERE t1.service_pack_id = #{@service_pack.id}
			SQL
		ActiveRecord::Base.connection.exec_query(q).to_hash
	end
	def json_rate_only
		hash_rate_only.to_json
	end
	def json_export(sym=:header)
		err = { :error => 422, :name => "Unsupported format"}
		sym == :header ? json_lite_header : (sym == :rate ? json_rate_only : err.to_json)
	end
end