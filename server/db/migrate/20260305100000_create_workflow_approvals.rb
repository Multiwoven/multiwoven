# frozen_string_literal: true

class CreateWorkflowApprovals < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_approvals do |t|
      t.references :workflow_run, null: false, foreign_key: { to_table: :workflow_runs }
      t.references :workspace, null: false, foreign_key: true
      t.string :component_id, null: false
      t.integer :status, null: false, default: 0
      t.text :message, null: false
      t.jsonb :input_data
      t.string :temporal_workflow_id, null: false
      t.string :temporal_run_id, null: false
      t.references :resolved_by, foreign_key: { to_table: :users }, null: true
      t.text :resolution_note
      t.datetime :timeout_at
      t.string :timeout_action, default: "reject"
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :workflow_approvals, :status
    add_index :workflow_approvals, %i[workflow_run_id component_id],
              unique: true,
              where: "status = 0",
              name: "idx_workflow_approvals_unique_pending"
  end
end
