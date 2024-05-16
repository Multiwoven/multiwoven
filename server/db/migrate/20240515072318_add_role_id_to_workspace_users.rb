class AddRoleIdToWorkspaceUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :workspace_users, :role
    add_reference :workspace_users, :role, null: false, foreign_key: true, default: Role.find_by(role_name: "Admin").id
  end
end
