class AddWorkflowRunIdToSyncRun < ActiveRecord::Migration[7.1]
  def change
    add_column :sync_runs, :workflow_run_id, :string
  end
end
