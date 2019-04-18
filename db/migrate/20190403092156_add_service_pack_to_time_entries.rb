class AddServicePackToTimeEntries < ActiveRecord::Migration[5.1]
	def change
		add_reference :time_entries, :service_pack
	end
end