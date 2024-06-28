# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConnectorDefinitionPolicy, type: :policy do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let(:workspace_user) { workspace.workspace_users.first }
  let(:record) { double("Record") }
  let(:context) { double("Context", user:, workspace:) }
  let(:policy) { described_class.new(context, record) }

  describe "#index?" do
    it "returns true when user is permitted to read connector definitions" do
      allow(policy).to receive(:permitted?).with(:read, :connector_definition).and_return(true)
      expect(policy.index?).to be_truthy
    end

    it "returns false when user is not permitted to read connector definitions" do
      allow(policy).to receive(:permitted?).with(:read, :connector_definition).and_return(false)
      expect(policy.index?).to be_falsey
    end
  end

  describe "#show?" do
    it "returns true when user is permitted to read connector definitions" do
      allow(policy).to receive(:permitted?).with(:read, :connector_definition).and_return(true)
      expect(policy.show?).to be_truthy
    end

    it "returns false when user is not permitted to read connector definitions" do
      allow(policy).to receive(:permitted?).with(:read, :connector_definition).and_return(false)
      expect(policy.show?).to be_falsey
    end
  end

  describe "#check_connection?" do
    it "returns true when user is permitted to create connector definitions" do
      allow(policy).to receive(:permitted?).with(:create, :connector_definition).and_return(true)
      expect(policy.check_connection?).to be_truthy
    end

    it "returns false when user is not permitted to create connector definitions" do
      allow(policy).to receive(:permitted?).with(:create, :connector_definition).and_return(false)
      expect(policy.check_connection?).to be_falsey
    end
  end
end
