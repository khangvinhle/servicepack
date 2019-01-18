class MappingRate < ApplicationRecord
  belongs_to :activity, class_name: 'TimeEntryActivity', foreign_key: 'activity_id'
  belongs_to :service_pack, inverse_of: :mapping_rates

  # validates_uniqueness_of :activity, scope: :service_pack

  def as_json
  	# hash literal example
  	{:name => activity.name, :rates => units_per_hour}
  end
end
