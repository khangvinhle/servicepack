class MappingRate < ApplicationRecord
  belongs_to :activity, class_name: 'TimeEntryActivity', foreign_key: 'activity_id'
  belongs_to :service_pack, inverse_of: :mapping_rates
end