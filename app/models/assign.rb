class Assign < ApplicationRecord
  belongs_to :service_pack
  belongs_to :project
  scope :active, -> {where(assigned: true)}
end
