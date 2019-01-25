class Assign < ApplicationRecord
	belongs_to :service_pack, dependent: :destroy
	belongs_to :project
	scope :active, ->{where("assigned = ? and unassigned_date > ?", true, Date.today)}
	def terminate
		self.assigned = false
		self.unassign_date = Date.today
		self.save!
	end
	def overdue?
		service_pack.unavailable?
	end
end
