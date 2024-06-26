# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncRecordPolicy, type: :policy do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let(:workspace_user) { workspace.workspace_users.first }
  let(:record) { double("sync_record") }
  let(:context) { double("Context", user:, workspace:) }
  let(:policy) { described_class.new(context, record) }

  describe "#index?" do
    it "returns true when user is permitted to read sync records" do
      allow(policy).to receive(:permitted?).with(:read, :sync_record).and_return(true)
      expect(policy.index?).to be_truthy
    end

    it "returns false when user is not permitted to read sync records" do
      allow(policy).to receive(:permitted?).with(:read, :sync_record).and_return(false)
      expect(policy.index?).to be_falsey
    end
  end
end
