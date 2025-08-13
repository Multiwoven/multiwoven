class CreateWorkflowRuns < ActiveRecord::Migration[7.0]
  def change
    create_table :workflow_runs do |t|
      t.uuid :workflow_id, null: false
      t.references :workspace, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.jsonb :inputs, default: {}
      t.jsonb :outputs, default: {}
      t.text :error_message
      t.string :temporal_workflow_id
      t.timestamps
    end
  end
end
