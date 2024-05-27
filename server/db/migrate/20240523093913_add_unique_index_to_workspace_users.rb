class AddUniqueIndexToWorkspaceUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :workspace_users, [:user_id, :workspace_id, :role_id], unique: true, name: 'index_workspace_users_on_user_workspace_role'
  end
end
