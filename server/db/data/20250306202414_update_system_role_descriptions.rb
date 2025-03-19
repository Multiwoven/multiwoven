# frozen_string_literal: true

class UpdateSystemRoleDescriptions < ActiveRecord::Migration[7.1]
  def change
    update_role_description(
      "Admin",
      "Full permissions for all resources and ability to manage workspace."
    )
    update_role_description(
      "Member",
      "Full permissions for all resources, but no access to manage workspace."
    )
    update_role_description(
      "Viewer",
      "Read permissions for all resources."
    )
  end

  private

  def update_role_description(role_name, role_desc)
    Role.find_by(role_name:)&.update!(role_desc:)
  end
end
