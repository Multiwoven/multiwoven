class AddWorkflowSessionsCountToWorkflow < ActiveRecord::Migration[7.1]
  def up
    add_column :workflows, :workflow_sessions_count, :integer, null: false, default: 0
  end

  def down
    remove_column :workflows, :workflow_sessions_count
  end
end
