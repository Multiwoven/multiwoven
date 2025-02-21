class CreateBillingSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :billing_subscriptions do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :billing_plan, null: false, foreign_key: true
      t.integer :status, default: 0
      t.integer :data_app_sessions, default: 0
      t.integer :feedback_count,  default: 0
      t.integer :rows_synced,  default: 0
      t.jsonb :addons_usage, default: {}

      t.timestamps
    end
  end
end
