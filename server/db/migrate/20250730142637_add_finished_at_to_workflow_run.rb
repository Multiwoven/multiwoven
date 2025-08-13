class AddFinishedAtToWorkflowRun < ActiveRecord::Migration[7.1]
  def up
    unless column_exists?(:workflow_runs, :finished_at)
      add_column :workflow_runs, :finished_at, :datetime
    end
  end

  def down
    if column_exists?(:workflow_runs, :finished_at)
      remove_column :workflow_runs, :finished_at
    end
  end
end
