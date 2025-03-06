# frozen_string_literal: true

require "rails_helper"

RSpec.describe Role, type: :model do
  describe "validations" do
    it { should validate_presence_of(:role_name) }
    it { should validate_presence_of(:policies) }
  end

  describe "associations" do
    it { should belong_to(:organization).optional }
  end

  describe "validations" do
    let(:organization) { create(:organization) }
    let(:role) { create(:role, organization:) }
    it "should not allow duplicate role names within the same organization" do
      new_role = build(:role, organization:, role_name: role.role_name)
      expect { new_role.save! }.to raise_error(ActiveRecord::RecordInvalid, /A role with this name already exists./)
    end

    it "should allow the same role name in different organizations" do
      new_role = build(:role, role_name: "new_role_name", organization:)
      expect(new_role.save!).to be_truthy
    end

    it "should allow the same role name in different organizations" do
      new_role = build(:role, role_name: "new_role_name", organization:)
      expect(new_role.save!).to be_truthy
    end

    it "should not allow reserved names for custom roles" do
      reserved_role = build(:role, role_name: "Admin", organization:, role_type: 0)
      expect(reserved_role).not_to be_valid
      expect(reserved_role.errors[:role_name]).to include("is a reserved name")

      reserved_role = build(:role, role_name: "Member", organization:, role_type: 0)
      expect(reserved_role).not_to be_valid
      expect(reserved_role.errors[:role_name]).to include("is a reserved name")

      reserved_role = build(:role, role_name: "Viewer", organization:, role_type: 0)
      expect(reserved_role).not_to be_valid
      expect(reserved_role.errors[:role_name]).to include("is a reserved name")
    end

    it "should allow non-reserved names for custom roles" do
      valid_role = build(:role, role_name: "custom_role", organization:, role_type: 0)
      expect(valid_role).to be_valid
    end
  end

  describe "grouped policies" do
    let(:role) do
      create(:role,
             policies: { "permissions" => {
               "alerts" => { "read" => true, "create" => false, "delete" => true, "update" => false },
               "billing" => { "read" => true, "create" => true, "delete" => false, "update" => true },
               "connector_definition" => { "read" => true, "create" => false, "delete" => false, "update" => false },
               "connector" => { "read" => true, "create" => true, "delete" => true, "update" => true },
               "model" => { "read" => false, "create" => true, "delete" => false, "update" => true },
               "sync" => { "read" => true, "create" => true, "delete" => true, "update" => true },
               "sync_run" => { "read" => true, "create" => false, "delete" => false, "update" => false },
               "sync_record" => { "read" => false, "create" => false, "delete" => true, "update" => false },
               "data_app" => { "read" => true, "create" => true, "delete" => false, "update" => true },
               "report" => { "read" => true, "create" => false, "delete" => false, "update" => false },
               "user" => { "read" => true, "create" => true, "delete" => false, "update" => true },
               "audit_logs" => { "read" => true, "create" => false, "delete" => false, "update" => false },
               "workspace" => { "read" => true, "create" => false, "delete" => false, "update" => true }
             } })
    end

    it "should correctly group policies" do
      # rubocop:disable Layout/LineLength
      expected_output = { "permissions" => {
        "alerts" => { "read" => true, "create" => false, "delete" => true, "update" => false, "group" => { "name" => "Alerts", "description" => "Manage and access alerts on syncs" } },
        "billing" => { "read" => true, "create" => true, "delete" => false, "update" => true, "group" => { "name" => "Billing", "description" => "Manage and access billing for your organization" } },
        "connector_definition" => { "read" => true, "create" => false, "delete" => false, "update" => false, "group" => { "name" => "Connectors", "description" => "Manage and access sources and destinations" } },
        "connector" => { "read" => true, "create" => true, "delete" => true, "update" => true, "group" => { "name" => "Connectors", "description" => "Manage and access sources and destinations" } },
        "model" => { "read" => false, "create" => true, "delete" => false, "update" => true, "group" => { "name" => "Models", "description" => "Manage and access models" } },
        "sync" => { "read" => true, "create" => true, "delete" => true, "update" => true, "group" => { "name" => "Syncs", "description" => "Manage and access syncs" } },
        "sync_run" => { "read" => true, "create" => false, "delete" => false, "update" => false, "group" => { "name" => "Syncs", "description" => "Manage and access syncs" } },
        "sync_record" => { "read" => false, "create" => false, "delete" => true, "update" => false, "group" => { "name" => "Syncs", "description" => "Manage and access syncs" } },
        "data_app" => { "read" => true, "create" => true, "delete" => false, "update" => true, "group" => { "name" => "Data Apps", "description" => "Manage and access data apps" } },
        "report" => { "read" => true, "create" => false, "delete" => false, "update" => false, "group" => { "name" => "Reports", "description" => "Manage and access reports for syncs and data apps" } },
        "user" => { "read" => true, "create" => true, "delete" => false, "update" => true, "group" => { "name" => "Workspace Management", "description" => "Manage and access workspaces, members, and audit logs" } },
        "audit_logs" => { "read" => true, "create" => false, "delete" => false, "update" => false, "group" => { "name" => "Workspace Management", "description" => "Manage and access workspaces, members, and audit logs" } },
        "workspace" => { "read" => true, "create" => false, "delete" => false, "update" => true, "group" => { "name" => "Workspace Management", "description" => "Manage and access workspaces, members, and audit logs" } }
      } }
      # rubocop:enable Layout/LineLength
      expect(JSON.parse(role.grouped_policies.to_json)).to eq(expected_output)
    end

    it "should give group permission count" do
      role.policies["permissions"]["alerts"]["read"] = false
      role.save!
      expected_output = { read: 6, create: 6, delete: 3, update: 6 }
      expect(role.group_permissions_count).to eq(expected_output)
    end
  end

  describe "permissions count" do
    let(:role) do
      create(:role,
             policies: { "permissions" => { "sync" => { "read" => true, "create" => true, "delete" => true,
                                                        "update" => true } } })
    end

    it "should count the total number of permissions" do
      expect(role.policies["permissions"]["sync"].count).to eq(4)
    end

    it "should return zero if no permissions are defined" do
      role_without_permissions = create(:role, policies: { permissions: {} })
      expect(role_without_permissions.policies["permissions"]).to be_empty
    end
  end

  describe "permissions count" do
    let(:role_with_permissions) do
      create(:role,
             policies: { "permissions" => { "sync" => { "read" => true, "create" => true, "delete" => true,
                                                        "update" => true } } })
    end

    let(:role_without_permissions) { create(:role, policies: { permissions: {} }) }
    let(:role_with_empty_permissions) { create(:role, policies: { "permissions" => {} }) }

    it "should count the total number of permissions correctly" do
      expect(role_with_permissions.permission_count).to eq({ read: 1, create: 1, delete: 1, update: 1 })
    end

    it "should return zero counts if no permissions are defined" do
      expect(role_without_permissions.permission_count).to eq({ read: 0, create: 0, delete: 0, update: 0 })
    end
  end

  describe "deletion restrictions" do
    let(:organization) { create(:organization) }
    let(:role) { create(:role, organization:, role_name: "Sync Monitor") }
    let(:workspace_user) { create(:workspace_user, role:) }

    context "when role has associated workspace users" do
      before { workspace_user }

      it "prevents deletion and returns appropriate error message" do
        expect(role.destroy).to be false
        expect(role.errors[:base]).to include(
          "You cannot delete Sync Monitor role as it is assigned to team members. " \
          "Please reassign or remove them before deleting this role."
        )
      end
    end

    context "when role has no associated workspace users" do
      it "allows deletion" do
        role.workspace_users.destroy_all
        expect(role.destroy).to be_truthy
      end
    end
  end

  describe "role_name uniqueness" do
    let(:organization) { create(:organization) }
    let(:existing_role) { create(:role, organization:, role_name: "Manager") }

    it "prevents duplicate role names within the same organization" do
      new_role = build(:role, organization:, role_name: existing_role.role_name)

      expect(new_role).not_to be_valid
      expect(new_role.errors[:role_name]).to include("A role with this name already exists.")
    end

    it "allows same role name in different organizations" do
      other_organization = create(:organization)
      new_role = build(:role, organization: other_organization, role_name: existing_role.role_name)

      expect(new_role).to be_valid
    end
  end
end
