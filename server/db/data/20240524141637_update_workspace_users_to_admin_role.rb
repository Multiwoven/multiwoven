# frozen_string_literal: true

class UpdateWorkspaceUsersToAdminRole < ActiveRecord::Migration[7.1]
  def change
    admin_role = Role.find_by(role_name: "Admin")
    WorkspaceUser.update_all(role_id: admin_role.id) # rubocop:disable Rails/SkipsModelValidations
  end
end
