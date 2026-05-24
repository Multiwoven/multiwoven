# frozen_string_literal: true

class AddAgenticCodingPermissionsToRoles < ActiveRecord::Migration[7.1]
  def up
    admin_role = Role.find_by(role_name: "Admin")
    member_role = Role.find_by(role_name: "Member")
    viewer_role = Role.find_by(role_name: "Viewer")

    [admin_role, member_role].compact.each do |role|
      current_permissions = role.policies["permissions"] || {}
      current_permissions["agentic_coding"] = { create: true, read: true, update: true, delete: true }
      role.update!(policies: { permissions: current_permissions })
    end

    viewer_role&.tap do |role|
      current_permissions = role.policies["permissions"] || {}
      current_permissions["agentic_coding"] = { create: false, read: true, update: false, delete: false }
      role.update!(policies: { permissions: current_permissions })
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
