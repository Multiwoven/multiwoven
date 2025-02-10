# frozen_string_literal: true

# spec/models/organization_spec.rb

require "rails_helper"

RSpec.describe Organization, type: :model do
  # Test for valid factory
  it "has a valid factory" do
    expect(build(:organization)).to be_valid
  end

  # Test validations
  describe "validations" do
    it { should validate_presence_of(:name) }
    # it { should validate_uniqueness_of(:name).case_insensitive }
    # Add other validations here
  end

  # Test associations
  describe "associations" do
    it { should have_many(:workspaces).dependent(:destroy) }
    it { should have_many(:workspace_users).through(:workspaces) }
    it { should have_many(:users).through(:workspace_users) }
    it { should have_many(:subscriptions).class_name("Billing::Subscription") }
    it { should have_one(:active_subscription).class_name("Billing::Subscription") }
  end

  describe "association functionality" do
    let(:organization) { create(:organization) }
    let(:workspace) { create(:workspace, organization:) }
    let(:user) { create(:user) }
    let(:workspace_user) { create(:workspace_user, workspace:, user:) }

    before do
      workspace
      user
      workspace_user
    end

    it "includes the correct workspace_users through workspaces" do
      expect(organization.workspace_users).to include(workspace_user)
    end

    it "includes the correct users through workspace_users" do
      expect(organization.users).to include(user)
    end
  end
end
