# frozen_string_literal: true

class AddRoles < ActiveRecord::Migration[7.1]
  def up
    Role.create!(
      role_name: "Admin",
      role_desc: "Administrator role with full access",
      policies: [
        {
          action: "allow",
          permissions: "*",
          resources: "*"
        }
      ]
    )

    Role.create!(
      role_name: "Member",
      role_desc: "Member role with basic access",
      policies: [
        {
          action: "allow",
          permissions: "*",
          resources: %w[
            connector_definition
            connector
            model
            report
            sync_record
            sync_run
            sync
            user
          ]
        }
      ]
    )
    Role.create!(
      role_name: "Viewer",
      role_desc: "Viewer role with read-only access",
      policies: [
        {
          action: "allow",
          permissions: ["read"],
          resources: %w[
            connector
            model
            report
            sync_record
            sync_run
            sync
            user
          ]
        }
      ]
    )
    Role.where(role_name: %w[Admin Viewer Member]).find_each do |role|
      role.system! if role.respond_to?(:system!)
    end
  end

  def down
    Role.where(role_name: %w[Admin Member Viewer]).destroy_all
  end
end
