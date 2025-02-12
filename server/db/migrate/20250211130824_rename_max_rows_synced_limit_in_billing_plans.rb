class RenameMaxRowsSyncedLimitInBillingPlans < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      rename_column :billing_plans, :max_rows_synced_limit, :max_rows_synced
    end
  end
end
