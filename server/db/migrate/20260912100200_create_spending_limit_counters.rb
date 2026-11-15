# frozen_string_literal: true

class CreateSpendingLimitCounters < ActiveRecord::Migration[7.2]
  def change
    create_table :spending_limit_counters do |t|
      t.references :spending_limit, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :window_start, null: false
      t.decimal :spent_cost, precision: 18, scale: 10, null: false, default: 0
      t.bigint :spent_tokens, null: false, default: 0
      t.bigint :request_count, null: false, default: 0
      t.integer :unpriced_requests, null: false, default: 0
      t.integer :alerted_thresholds, array: true, null: false, default: []

      t.timestamps

      t.check_constraint "spent_cost >= 0 AND spent_tokens >= 0 AND request_count >= 0 AND unpriced_requests >= 0",
                         name: "spending_limit_counters_totals_non_negative"
      t.index %i[spending_limit_id window_start], unique: true,
                                                  name: "index_spending_limit_counters_on_limit_and_window_start"
    end
  end
end
