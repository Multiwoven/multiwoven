# frozen_string_literal: true

class UpdateAssistantPermissionsForRoles < ActiveRecord::Migration[7.1]
  def up
    member_role = Role.find_by(role_name: "Member")
    viewer_role = Role.find_by(role_name: "Viewer")

    member_role&.tap do |role|
      current_permissions = role.policies["permissions"] || {}
      current_permissions["assistant"] = { create: true, read: true, update: true, delete: true }
      role.update!(policies: { permissions: current_permissions })
    end

    viewer_role&.tap do |role|
      current_permissions = role.policies["permissions"] || {}
      current_permissions["assistant"] = { create: false, read: true, update: false, delete: false }
      role.update!(policies: { permissions: current_permissions })
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
