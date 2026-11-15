# frozen_string_literal: true

class AddCountingStartedAtToSpendingLimits < ActiveRecord::Migration[7.2]
  # safety_assured: now() is STABLE, so PostgreSQL stores a fast default and does not rewrite.
  def change
    safety_assured do
      add_column :spending_limits, :counting_started_at, :datetime, null: false,
                                                                    default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
