class AddAlertMediumToAlertChannels < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_reference :alert_channels, :alert_medium, null: false, index: {algorithm: :concurrently}
  end
end
