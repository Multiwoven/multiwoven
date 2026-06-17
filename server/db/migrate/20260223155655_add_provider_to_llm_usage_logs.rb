class AddProviderToLlmUsageLogs < ActiveRecord::Migration[7.1]
  def up
    add_column :llm_usage_logs, :provider, :string
  end

  def down
    remove_column :llm_usage_logs, :provider
  end
end
