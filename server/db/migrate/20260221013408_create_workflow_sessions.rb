class CreateWorkflowSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_sessions do |t|
      t.string :session_id, null: false
      t.uuid :workflow_id, null: false
      t.integer :workspace_id, null: false
      t.string :title
      t.datetime :start_time, null: false
      t.datetime :end_time
      t.timestamps 
    end
    add_index :workflow_sessions, :session_id, unique: true, name: 'index_workflow_sessions_on_session_id'
    add_index :workflow_sessions, :workflow_id, name: 'index_workflow_sessions_on_workflow_id'
    add_index :workflow_sessions, :workspace_id, name: 'index_workflow_sessions_on_workspace_id'

    add_foreign_key :workflow_sessions, :workflows, column: :workflow_id, validate: false
    add_foreign_key :workflow_sessions, :workspaces, column: :workspace_id, validate: false
  end
end
