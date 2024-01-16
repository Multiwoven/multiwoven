class RemoveActionFromSyncRuns < ActiveRecord::Migration[7.1]
  def change
    remove_column :sync_runs, :action, :integer
  end
end
