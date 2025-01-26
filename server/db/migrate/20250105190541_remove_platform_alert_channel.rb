class RemovePlatformAlertChannel < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :alert_channels, :platform }
  end
end
