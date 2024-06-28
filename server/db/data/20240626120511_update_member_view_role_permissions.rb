# frozen_string_literal: true

class UpdateMemberViewRolePermissions < ActiveRecord::Migration[7.1]
  def change
    member_role = Role.find_by(role_name: "Member")
    viewer_role = Role.find_by(role_name: "Viewer")

    member_role.update!(
      policies: {
        permissions: {
          connector_definition: { create: true, read: true, update: true, delete: true },
          connector: { create: true, read: true, update: true, delete: true },
          model: { create: true, read: true, update: true, delete: true },
          report: { create: true, read: true, update: true, delete: true },
          sync_record: { create: true, read: true, update: true, delete: true },
          sync_run: { create: true, read: true, update: true, delete: true },
          sync: { create: true, read: true, update: true, delete: true },
          user: { create: false, read: false, update: false, delete: false },
          workspace: { create: false, read: true, update: false, delete: false }
        }
      }
    )

    viewer_role&.update!(
      policies: {
        permissions: {
          connector_definition: { create: false, read: true, update: false, delete: false },
          connector: { create: false, read: true, update: false, delete: false },
          model: { create: false, read: true, update: false, delete: false },
          report: { create: false, read: true, update: false, delete: false },
          sync_record: { create: false, read: true, update: false, delete: false },
          sync_run: { create: false, read: true, update: false, delete: false },
          sync: { create: false, read: true, update: false, delete: false },
          user: { create: false, read: false, update: false, delete: false },
          workspace: { create: false, read: true, update: false, delete: false }
        }
      }
    )
  end
end
