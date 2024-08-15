class AddSyncRunTypeToSyncRuns < ActiveRecord::Migration[7.1]
  def change
    add_column :sync_runs, :sync_run_type, :integer, default: 0
  end
end
