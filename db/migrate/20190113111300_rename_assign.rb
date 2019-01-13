class RenameAssign < ActiveRecord::Migration[5.1]
	def change
		# keep this name because of consensus
		rename_column :assigns, :unassigned, :assigned
	end
end