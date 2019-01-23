class FeatureADone < ActiveRecord::Migration[5.1]
	# enforce NOT NULL constraint
	# false means NULL is not accepted.
	def change
		change_column_null :assigns, :unassign_date, false
		change_column_null :assigns, :assign_date, false
		change_column_null :service_pack_entries, :time_entry_id, false
		change_column_null :service_pack_entries, :units, false
		change_column_null :mapping_rates, :activity_id, false
		change_column_null :mapping_rates, :service_pack_id, false
		change_column_null :mapping_rates, :units_per_hour, false
		if !index_exists?(:mapping_rates, [:service_pack_id, :activity_id])
			add_index :mapping_rates, [:service_pack_id, :activity_id], unique: true
		end
	end
end