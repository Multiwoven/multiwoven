class ValidateAddForeignKeyAlertMediumToAlertChannel < ActiveRecord::Migration[7.1]
  def change
    validate_foreign_key :alert_channels, :alert_media
  end
end
