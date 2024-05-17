class AddRoleIdToWorkspaceUsers < ActiveRecord::Migration[7.1]
  def change
    if column_exists?(:workspace_users, :role)
      remove_column :workspace_users, :role
    end
    unless column_exists?(:workspace_users, :role_id)
      add_reference :workspace_users, :role, null: false, foreign_key: true, default: nil
    end
  end
end
