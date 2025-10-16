class ChangeWorkflowIdFromStringtoUuidInWorkflowIntegration < ActiveRecord::Migration[7.1]
  def up
    safety_assured { change_column :workflow_integrations, :workflow_id, 'uuid USING workflow_id::uuid' }
    add_foreign_key :workflow_integrations, :workflows, column: :workflow_id, validate: false
  end

  def down
    safety_assured { change_column :workflow_integrations, :workflow_id, :string }
    remove_foreign_key :workflow_integrations, column: :workflow_id
  end
end
