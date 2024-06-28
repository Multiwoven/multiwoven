# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConnectorPolicy, type: :policy do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let(:workspace_user) { workspace.workspace_users.first }
  let(:connector) { create(:connector) }
  let(:record) { connector }
  let(:context) { double("Context", user:, workspace:) }
  let(:policy) { described_class.new(context, record) }

  describe "#index?" do
    it "returns true when user is permitted to read connectors" do
      allow(policy).to receive(:permitted?).with(:read, :connector).and_return(true)
      expect(policy.index?).to be_truthy
    end

    it "returns false when user is not permitted to read connectors" do
      allow(policy).to receive(:permitted?).with(:read, :connector).and_return(false)
      expect(policy.index?).to be_falsey
    end
  end

  describe "#show?" do
    it "returns true when user is permitted to read connectors" do
      allow(policy).to receive(:permitted?).with(:read, :connector).and_return(true)
      expect(policy.show?).to be_truthy
    end

    it "returns false when user is not permitted to read connectors" do
      allow(policy).to receive(:permitted?).with(:read, :connector).and_return(false)
      expect(policy.show?).to be_falsey
    end
  end

  describe "#create?" do
    it "returns true when user is permitted to create connectors" do
      allow(policy).to receive(:permitted?).with(:create, :connector).and_return(true)
      expect(policy.create?).to be_truthy
    end

    it "returns false when user is not permitted to create connectors" do
      allow(policy).to receive(:permitted?).with(:create, :connector).and_return(false)
      expect(policy.create?).to be_falsey
    end
  end

  describe "#update?" do
    it "returns true when user is permitted to update connectors" do
      allow(policy).to receive(:permitted?).with(:update, :connector).and_return(true)
      expect(policy.update?).to be_truthy
    end

    it "returns false when user is not permitted to update connectors" do
      allow(policy).to receive(:permitted?).with(:update, :connector).and_return(false)
      expect(policy.update?).to be_falsey
    end
  end

  describe "#destroy?" do
    it "returns true when user is permitted to delete connectors" do
      allow(policy).to receive(:permitted?).with(:delete, :connector).and_return(true)
      expect(policy.destroy?).to be_truthy
    end

    it "returns false when user is not permitted to delete connectors" do
      allow(policy).to receive(:permitted?).with(:delete, :connector).and_return(false)
      expect(policy.destroy?).to be_falsey
    end
  end

  describe "#discover?" do
    it "returns true when user is permitted to read connectors" do
      allow(policy).to receive(:permitted?).with(:read, :connector).and_return(true)
      expect(policy.discover?).to be_truthy
    end

    it "returns false when user is not permitted to read connectors" do
      allow(policy).to receive(:permitted?).with(:read, :connector).and_return(false)
      expect(policy.discover?).to be_falsey
    end
  end

  describe "#query_source?" do
    it "returns true when user is permitted to read connectors" do
      allow(policy).to receive(:permitted?).with(:read, :connector).and_return(true)
      expect(policy.query_source?).to be_truthy
    end

    it "returns false when user is not permitted to read connectors" do
      allow(policy).to receive(:permitted?).with(:read, :connector).and_return(false)
      expect(policy.query_source?).to be_falsey
    end
  end
end
