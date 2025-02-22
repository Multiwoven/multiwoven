# frozen_string_literal: true

require "rails_helper"

RSpec.describe Role, type: :model do
  describe "validations" do
    it { should validate_presence_of(:role_name) }
    it { should validate_presence_of(:policies) }
  end
<<<<<<< HEAD
=======

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
>>>>>>> 52e4e72b (feat(CE): add group meta to resource (#872))
end
