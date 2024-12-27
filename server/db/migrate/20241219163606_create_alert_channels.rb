class CreateAlertChannels < ActiveRecord::Migration[7.1]
  def change
    create_table :alert_channels do |t|
      t.references :alert, null: false, foreign_key: true
      t.integer :platform, null: false
      t.jsonb :configuration
      t.timestamps
    end
  end
end
