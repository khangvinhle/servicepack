class ServicePackEntry < ApplicationRecord
	belongs_to :time_entry
	belongs_to :service_pack
end
