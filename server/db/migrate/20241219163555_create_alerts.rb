class CreateAlerts < ActiveRecord::Migration[7.1]
  def change
    create_table :alerts do |t|
      t.string :name
      t.references :workspace, null: false, foreign_key: true
      t.boolean :alert_sync_success, default: false
      t.boolean :alert_sync_failure, default: false
      t.boolean :alert_row_failure, default: false
      t.integer :row_failure_threshold_percent
      t.timestamps
    end
  end
end
