class ServicePackPresenter
	attr_reader: :service_pack
	def initialize(service_pack)
		# we don't take NIL as an option
		if service_pack && service_pack.id
			@service_pack = service_pack
		else
			raise "This is NIL cannot print"
		end
	end
	def json_full_header
		#not recommended in production
		@service_pack.to_json
	end
	def hash_lite_header
		@service_pack.as_json(except: [:id, :threshold1, :threshold2, :updated_on])
	end
	def json_lite_header
		hash_lite_header.to_json
	end
	def hash_rate_only

	end
end