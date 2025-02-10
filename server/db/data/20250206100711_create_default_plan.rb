# frozen_string_literal: true

class CreateDefaultPlan < ActiveRecord::Migration[7.1]
  def up
    Billing::Plan.create!(
      name: "Starter",
      status: 0,
      amount: 0,
      currency: 0,
      interval: 0,
      max_data_app_sessions: 10_000,
      max_feedback_count: 1_000,
      max_rows_synced_limit: 100_000
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
