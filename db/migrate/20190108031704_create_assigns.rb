class CreateAssigns < ActiveRecord::Migration[5.1]
  def change
    create_table :assigns do |t|
      t.belongs_to :service_packs
      t.belongs_to :projects
      t.date :assign_date, null: false
      t.timestamps
    end
    add_column(:assigns, :unassigned, :boolean, default: true, null: false)
  end
end
