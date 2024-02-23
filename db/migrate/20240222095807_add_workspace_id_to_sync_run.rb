class AddWorkspaceIdToSyncRun < ActiveRecord::Migration[7.1]
  def change
    add_column :sync_runs, :workspace_id, :integer
  end
end
