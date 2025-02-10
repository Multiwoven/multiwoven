class CreateBillingPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :billing_plans do |t|
      t.string :name, null: false 
      t.integer :status, default: 0
      t.float :amount, default: 0
      t.integer :currency, default: 0
      t.integer :interval, default: 0
      t.integer :max_data_app_sessions
      t.integer :max_feedback_count, default: 0
      t.integer :max_rows_synced_limit, default: 0
      t.text :addons_config

      t.timestamps
    end
  end
end
