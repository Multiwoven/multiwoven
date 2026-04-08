# frozen_string_literal: true

class CreatePromptToWorkflowSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :prompt_to_workflow_sessions do |t|
      t.uuid :session_id, null: false
      t.uuid :workflow_id, null: false
      t.integer :workspace_id, null: false
      t.string :status, null: false, default: "running"
      t.uuid :current_clarification_id
      t.jsonb :state, null: false, default: {}
      t.string :temporal_workflow_id
      t.string :temporal_run_id
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :prompt_to_workflow_sessions, :session_id, unique: true
    add_index :prompt_to_workflow_sessions, :workflow_id
    add_index :prompt_to_workflow_sessions, :workspace_id
    add_index :prompt_to_workflow_sessions, %i[workspace_id status], name: "idx_p2w_sessions_workspace_status"
    add_index :prompt_to_workflow_sessions, %i[status expires_at], name: "idx_p2w_sessions_status_expires"
    add_index :prompt_to_workflow_sessions, :expires_at

    add_foreign_key :prompt_to_workflow_sessions, :workflows, column: :workflow_id, validate: false
    add_foreign_key :prompt_to_workflow_sessions, :workspaces, column: :workspace_id, validate: false
  end
end
