class AddActionToSyncRuns < ActiveRecord::Migration[7.1]
  def change
    add_column :sync_runs, :action, :integer
  end
end
