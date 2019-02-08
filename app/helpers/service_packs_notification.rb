module ServicePacksNotification

	def self.notify_under_threshold1
		# https://blog.arkency.com/2013/12/rails4-preloading/
		service_packs = ServicePack.where('remained_units <= total_units / 100.0 * threshold1').preload(:consuming_projects)
		service_packs do |sp|
			sp.consuming_projects do |project|
				users = User.allowed_to({controller: :assigns, action: :show}, project)
				users.each ->(user) { ServicePackMailer.notify_under_threshold1(user, sp) }
			end
		end
	end
end