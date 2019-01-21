class FinalAssignsTable < ActiveRecord::Migration[5.1]
	def change
		add_column :assigns, :unassign_date, :date
	end
end