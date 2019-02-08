class Assign < ApplicationRecord
	belongs_to :service_pack
	belongs_to :project
	scope :active, ->{where("assigned = ? and unassign_date > ?", true, Date.today)}
	def terminate
		self.assigned = false
		self.unassign_date = Date.today
		self.save!
	end
	def overdue?
		service_pack.unavailable?
	end
end
