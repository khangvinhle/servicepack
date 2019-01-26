class ServicePackEntry < ApplicationRecord
	belongs_to :time_entry, dependent: :destroy
	belongs_to :service_pack, inverse_of: :service_pack_entries
end
