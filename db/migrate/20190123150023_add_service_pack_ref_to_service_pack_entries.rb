class AddServicePackRefToServicePackEntries < ActiveRecord::Migration[5.1]
  def change
    add_reference :service_pack_entries, :service_pack, foreign_key: true
  end
end
