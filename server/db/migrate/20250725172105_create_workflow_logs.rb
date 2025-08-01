class CreateWorkflowLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_logs do |t|
      t.string :workflow_id, null: false
      t.integer :workflow_run_id, null: false
      t.string :input, null: false
      t.string :output
      t.jsonb :logs, default: {}
      t.integer :workspace_id, null: false

      t.timestamps
    end
  end
end
