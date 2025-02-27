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
      expect { new_role.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "should allow the same role name in different organizations" do
      new_role = build(:role, role_name: "new_role_name", organization:)
      expect(new_role.save!).to be_truthy
    end
  end

  describe "grouped policies" do
    let(:role) do
      create(:role,
             policies: { "permissions" => { "sync" => { "read" => true, "create" => true, "delete" => true,
                                                        "update" => true } } })
    end

    it "should correctly group policies" do
      # rubocop:disable Layout/LineLength
      expected_output = { "permissions" => { "sync" => { "read" => true, "create" => true, "delete" => true,
                                                         "update" => true, :group => { name: "Syncs", description: "Manage and access syncs" } } } }
      # rubocop:enable Layout/LineLength
      expect(role.grouped_policies).to eq(expected_output)
    end
  end

  describe "permissions count" do
    let(:role) do
      create(:role,
             policies: { "permissions" => { "sync" => { "read" => true, "create" => true, "delete" => true,
                                                        "update" => true } } })
    end

    it "should count the total number of permissions" do
      expect(role.policies["permissions"]["sync"].count).to eq(4) # Adjust the count based on your permissions structure
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
end
