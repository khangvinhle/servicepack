class ChangeUnitsOfServicePackEntries < ActiveRecord::Migration[5.1]
  def change
  	change_column :service_pack_entries, :units, :float
  end
end
