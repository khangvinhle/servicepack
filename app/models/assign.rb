class Assign < ApplicationRecord
  belongs_to :service_pack
  belongs_to :project
  # scope :active, -> {where(assigned: true)}
  def terminate
	self.assigned = false
	self.save!
  end
  def overdue?
	service_pack.unavailable?
  end
end
