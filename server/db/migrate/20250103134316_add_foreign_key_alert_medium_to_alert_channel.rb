class AddForeignKeyAlertMediumToAlertChannel < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :alert_channels, :alert_media, column: :alert_medium_id, validate: false
  end
end
