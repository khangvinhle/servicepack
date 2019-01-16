class CreateServicePackEntries < ActiveRecord::Migration[5.1]
  def change
    create_table :service_pack_entries do |t|
    	t.belongs_to :time_entry
    	t.integer :units
      	t.timestamps
    end
  end
end
