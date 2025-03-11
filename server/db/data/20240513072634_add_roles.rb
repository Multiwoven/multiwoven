# frozen_string_literal: true

class AddRoles < ActiveRecord::Migration[7.1]
  def up # rubocop:disable Metrics/MethodLength
    role_type_present = Role.column_names.include?("role_type")

    roles = [
      {
        role_name: "Admin",
        role_desc: "Administrator role with full access",
        policies: [
          {
            action: "allow",
            permissions: "*",
            resources: "*"
          }
        ]
      },
      {
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
      },
      {
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
      }
    ]

    roles.each do |role|
      role[:role_type] = "system" if role_type_present
      Role.create!(role)
    end
  end

  def down
    Role.where(role_name: %w[Admin Member Viewer]).destroy_all
  end
end
