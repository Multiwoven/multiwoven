# frozen_string_literal: true

class AddAbandonedAtToSpendingLimitAlerts < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  PENDING_INDEX = "index_spend_alerts_pending"

  def up
    add_column :spending_limit_alerts, :abandoned_at, :datetime

    # The sweep's query narrows on both columns, so the partial index has to as well. The old
    # index is dropped only once its replacement is in place.
    add_index :spending_limit_alerts, :id, where: "delivered_at IS NULL AND abandoned_at IS NULL",
                                           name: "#{PENDING_INDEX}_v2", algorithm: :concurrently
    remove_index :spending_limit_alerts, name: PENDING_INDEX, algorithm: :concurrently
  end

  def down
    add_index :spending_limit_alerts, :id, where: "delivered_at IS NULL",
                                           name: PENDING_INDEX, algorithm: :concurrently
    remove_index :spending_limit_alerts, name: "#{PENDING_INDEX}_v2", algorithm: :concurrently
    remove_column :spending_limit_alerts, :abandoned_at
  end
end
