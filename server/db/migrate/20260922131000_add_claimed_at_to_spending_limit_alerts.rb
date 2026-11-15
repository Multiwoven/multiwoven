# frozen_string_literal: true

class AddClaimedAtToSpendingLimitAlerts < ActiveRecord::Migration[7.2]
  def change
    add_column :spending_limit_alerts, :claimed_at, :datetime
  end
end
