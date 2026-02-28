class AddTotalCostToLlmUsageLogs < ActiveRecord::Migration[7.1]
  def up
    add_column :llm_usage_logs, :total_cost, :float, null: false, default: 0.0
  end

  def down
    remove_column :llm_usage_logs, :total_cost
  end
end
