class CreateMappingRates < ActiveRecord::Migration[5.1]
  def change
    create_table :mapping_rates do |t|
    	t.integer :activity_id
      	t.belongs_to :service_pack
      	t.integer :units_per_hour
      	t.timestamps
    end
  end
end
