# frozen_string_literal: true

class AddSpendingLimitPermissionsToRoles < ActiveRecord::Migration[7.1]
  def up
    unless Resource.exists?(resources_name: "spending_limit")
      resource = Resource.create!(
        resources_name: "spending_limit",
        permissions: %w[create read update delete]
      )
      puts "Resource '#{resource.resources_name}' created successfully with permissions: #{resource.permissions}"
    end

    admin_role = Role.find_by(role_name: "Admin")
    member_role = Role.find_by(role_name: "Member")
    viewer_role = Role.find_by(role_name: "Viewer")

    admin_role&.tap do |role|
      current_permissions = role.policies["permissions"] || {}
      current_permissions["spending_limit"] = { create: true, read: true, update: true, delete: true }
      role.update!(policies: { permissions: current_permissions })
    end

    [member_role, viewer_role].compact.each do |role|
      current_permissions = role.policies["permissions"] || {}
      current_permissions["spending_limit"] = { create: false, read: true, update: false, delete: false }
      role.update!(policies: { permissions: current_permissions })
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
