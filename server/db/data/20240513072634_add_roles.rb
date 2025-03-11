# frozen_string_literal: true

class AddRoles < ActiveRecord::Migration[7.1]
  def up # rubocop:disable Metrics/MethodLength
    Role.create!(
      role_name: "Admin",
      role_desc: "Administrator role with full access",
      role_type: "system",
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
      role_type: "system",
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
      role_type: "system",
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
  end

  def down
    Role.where(role_name: %w[Admin Member Viewer]).destroy_all
  end
end
