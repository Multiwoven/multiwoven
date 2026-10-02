# frozen_string_literal: true

class CreateSpendingLimitAlerts < ActiveRecord::Migration[7.2]
  def change
    create_table :spending_limit_alerts do |t|
      # index: false, because the unique index below leads with this column and serves the cascade,
      # which is load bearing: counters are removed with delete_all.
      t.references :spending_limit_counter, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :threshold, null: false
      t.datetime :delivered_at

      t.timestamps

      t.index %i[spending_limit_counter_id threshold], unique: true,
                                                       name: "index_spend_alerts_on_counter_and_threshold"
      t.index :id, where: "delivered_at IS NULL", name: "index_spend_alerts_pending"
    end
  end
end
