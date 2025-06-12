# frozen_string_literal: true

class AddUniqueIndexToWorkflows < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_index :workflows, [:workspace_id, :name], unique: true,
      name: 'index_workflows_on_workspace_id_and_name', algorithm: :concurrently
  end

  def down
    remove_index :workflows, name: 'index_workflows_on_workspace_id_and_name', algorithm: :concurrently
  end
end
