module ServicePacksNotification

	def self.notify_under_threshold1
		# https://blog.arkency.com/2013/12/rails4-preloading/
		assignments = Assign.active.eager_load(:service_pack)
		assignments = assignments.where("service_packs.remained_units <= service_packs.total_units/100.0*threshold1")
		assignments = assignments.eager_load(:project)
		# puts assignments.to_sql
		return if assignments.empty?
		triplet = []
		assignments.each do |assignment|
			# Users.allowed
		end
	end
end