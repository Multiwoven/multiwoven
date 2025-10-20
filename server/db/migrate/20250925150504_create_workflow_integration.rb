class CreateWorkflowIntegration < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_integrations, id: :uuid do |t|
      t.jsonb :metadata, null: false
      t.integer :workspace_id, null: false
      t.string :workflow_id, null: false

      t.timestamps
    end

    add_foreign_key :workflow_integrations, :workspaces, validate: false
  end
end
