class AddDescriptionToServicePackEntries < ActiveRecord::Migration[5.1]
  def change
    add_column :service_pack_entries, :description, :text
  end
end
