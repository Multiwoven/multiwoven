# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncRunPolicy, type: :policy do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let(:workspace_user) { workspace.workspace_users.first }
  let(:record) { double("sync_run") }
  let(:context) { double("Context", user:, workspace:) }
  let(:policy) { described_class.new(context, record) }

  describe "#index?" do
    it "returns true when user is permitted to read sync runs" do
      allow(policy).to receive(:permitted?).with(:read, :sync_run).and_return(true)
      expect(policy.index?).to be_truthy
    end

    it "returns false when user is not permitted to read sync runs" do
      allow(policy).to receive(:permitted?).with(:read, :sync_run).and_return(false)
      expect(policy.index?).to be_falsey
    end
  end

  describe "#show?" do
    it "returns true when user is permitted to read a sync run" do
      allow(policy).to receive(:permitted?).with(:read, :sync_run).and_return(true)
      expect(policy.show?).to be_truthy
    end

    it "returns false when user is not permitted to read a sync run" do
      allow(policy).to receive(:permitted?).with(:read, :sync_run).and_return(false)
      expect(policy.show?).to be_falsey
    end
  end
end
