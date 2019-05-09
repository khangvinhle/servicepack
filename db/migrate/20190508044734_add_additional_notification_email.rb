class AddAdditionalNotificationEmail < ActiveRecord::Migration[5.1]
  def change
    add_column(:service_packs, :additional_notification_email, :string, null: true)
  end
end
