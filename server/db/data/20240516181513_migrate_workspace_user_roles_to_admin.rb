# frozen_string_literal: true

class MigrateWorkspaceUserRolesToAdmin < ActiveRecord::Migration[7.1]
  def change
    admin_role = Role.find_by(role_name: "Admin")
    WorkspaceUser.where(role_id: admin_role.id).find_each do |workspace_user_role|
      workspace_user_role.update(role_id: admin_role.id)
    end
  end
end
