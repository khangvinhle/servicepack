class MappingRate < ApplicationRecord
  # DO NOT ADD :inverse_of TO THIS CLASS - it breaks the SP#edit and #new
  belongs_to :activity, class_name: 'TimeEntryActivity', foreign_key: 'activity_id'
  belongs_to :service_pack
  # validates_uniqueness_of :activity, scope: :service_pack

  validates_numericality_of :units_per_hour, greater_than_or_equal_to: 0
  validate :only_define_rates_on_shared_activity

  private
  	def only_define_rates_on_shared_activity
  		errors.add(:activity, 'invalid') if !activity.shared?
  	end
end
