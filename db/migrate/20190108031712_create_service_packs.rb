class CreateServicePacks < ActiveRecord::Migration[5.1]
  def change
    create_table :service_packs do |t|
      t.string :name, null: false
      t.integer :total_units, null: false
      t.integer :remain_units, null: false
      t.date :start_date, null: false
      t.date :expired_date, null: false
      t.integer :threshold1, null: false
      t.integer :threshold2, null: false
      t.integer :management, null: false
      t.integer :developent, null: false
      t.integer :other, null: false
      t.integer :testing, null: false
      t.integer :support, null: false
      t.integer :specification, null: false
      t.timestamps
    end
  end
end
