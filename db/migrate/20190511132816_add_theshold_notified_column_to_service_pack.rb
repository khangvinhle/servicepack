class AddThesholdNotifiedColumnToServicePack < ActiveRecord::Migration[5.1]
  def change
    add_column(:service_packs, :threshold1_notified, :boolean, null: false, default: false)
    add_column(:service_packs, :threshold2_notified, :boolean, null: false, default: false)
  end
end
