# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncPolicy, type: :policy do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let(:workspace_user) { workspace.workspace_users.first }
  let(:record) { double("sync") }
  let(:context) { double("Context", user:, workspace:) }
  let(:policy) { described_class.new(context, record) }

  describe "#index?" do
    it "returns true when user is permitted to read sync" do
      allow(policy).to receive(:permitted?).with(:read, :sync).and_return(true)
      expect(policy.index?).to be_truthy
    end

    it "returns false when user is not permitted to read sync" do
      allow(policy).to receive(:permitted?).with(:read, :sync).and_return(false)
      expect(policy.index?).to be_falsey
    end
  end

  describe "#show?" do
    it "returns true when user is permitted to read sync" do
      allow(policy).to receive(:permitted?).with(:read, :sync).and_return(true)
      expect(policy.show?).to be_truthy
    end

    it "returns false when user is not permitted to read sync" do
      allow(policy).to receive(:permitted?).with(:read, :sync).and_return(false)
      expect(policy.show?).to be_falsey
    end
  end

  describe "#create?" do
    it "returns true when user is permitted to create sync" do
      allow(policy).to receive(:permitted?).with(:create, :sync).and_return(true)
      expect(policy.create?).to be_truthy
    end

    it "returns false when user is not permitted to create sync" do
      allow(policy).to receive(:permitted?).with(:create, :sync).and_return(false)
      expect(policy.create?).to be_falsey
    end
  end

  describe "#update?" do
    it "returns true when user is permitted to update sync" do
      allow(policy).to receive(:permitted?).with(:update, :sync).and_return(true)
      expect(policy.update?).to be_truthy
    end

    it "returns false when user is not permitted to update sync" do
      allow(policy).to receive(:permitted?).with(:update, :sync).and_return(false)
      expect(policy.update?).to be_falsey
    end
  end

  describe "#destroy?" do
    it "returns true when user is permitted to delete sync" do
      allow(policy).to receive(:permitted?).with(:delete, :sync).and_return(true)
      expect(policy.destroy?).to be_truthy
    end

    it "returns false when user is not permitted to delete sync" do
      allow(policy).to receive(:permitted?).with(:delete, :sync).and_return(false)
      expect(policy.destroy?).to be_falsey
    end
  end

  describe "#configurations?" do
    it "returns true when user is permitted to read sync" do
      allow(policy).to receive(:permitted?).with(:read, :sync).and_return(true)
      expect(policy.configurations?).to be_truthy
    end

    it "returns false when user is not permitted to read sync" do
      allow(policy).to receive(:permitted?).with(:read, :sync).and_return(false)
      expect(policy.configurations?).to be_falsey
    end
  end
end
