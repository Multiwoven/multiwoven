class AddWorkflowIdToSyncs < ActiveRecord::Migration[7.1]
  def change
    add_column :syncs, :workflow_id, :string
  end
end
