# frozen_string_literal: true

class UpdateRoleDescriptions < ActiveRecord::Migration[7.1]
  def change
    update_role_description(
      "Admin",
      "An Admin can add and manage Sources, Destinations, Models, Syncs, and Workspaces."
    )
    update_role_description(
      "Member",
      "A Member can add and manage Sources, Destinations, Models, and Syncs but cannot manage the Workspaces."
    )
    update_role_description(
      "Viewer",
      "A Viewer has read-only access to the already created Sources, Destinations, Models, and Syncs and cannot manage"\
      " the Workspaces."
    )
  end

  private

  def update_role_description(role_name, role_desc)
    Role.find_by(role_name:)&.update!(role_desc:)
  end
end
