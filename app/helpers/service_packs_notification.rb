module ServicePacksNotification

	def self.notify_under_threshold1
		# https://blog.arkency.com/2013/12/rails4-preloading/
		service_packs = ServicePack.where('remained_units <= total_units / 100.0 * threshold1').preload(:consuming_projects)
		ServicePack.find_each do |sp|
			sp.consuming_projects.find_each do |project|
				users = User.allowed(:see_assigned_service_packs, project)
				users.each do |user| ServicePacksMailer.notify_under_threshold1(user, sp).deliver_later end
			end
		end
	end
end