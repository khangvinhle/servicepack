class Ana < ActiveRecord::Migration[5.1]
	def change
		# denorm
		add_reference :service_pack_entries, :service_pack, null: false
	end
end