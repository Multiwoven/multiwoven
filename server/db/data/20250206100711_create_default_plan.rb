# frozen_string_literal: true

class CreateDefaultPlan < ActiveRecord::Migration[7.1]
  def up
    plan = Billing::Plan.new(
      name: "Starter",
      status: 0,
      amount: 0,
      currency: 0,
      interval: 0,
      max_data_app_sessions: 10_000,
      max_feedback_count: 1_000
    )
    if Billing::Plan.column_names.include?("max_rows_synced_limit")
      plan.max_rows_synced_limit = 100_000
    else
      plan.max_rows_synced = 100_000
    end

    plan.save!
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
