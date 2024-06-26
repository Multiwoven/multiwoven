# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationPolicy, type: :policy do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let(:workspace_user) { workspace.workspace_users.first }
  let(:record) { double("Record") }
  let(:context) { double("Context", user:, workspace:) }
  let(:policy) { described_class.new(context, record) }

  describe "#index?" do
    it "returns false" do
      expect(policy.index?).to be_falsey
    end
  end

  describe "#show?" do
    it "returns false" do
      expect(policy.show?).to be_falsey
    end
  end

  describe "#create?" do
    it "returns false" do
      expect(policy.create?).to be_falsey
    end
  end

  describe "#update?" do
    it "returns false" do
      expect(policy.update?).to be_falsey
    end
  end

  describe "#destroy?" do
    it "returns false" do
      expect(policy.destroy?).to be_falsey
    end
  end

  describe "#role_permissions" do
    context "when user has a role in the workspace" do
      before do
        allow(workspace).to receive_message_chain(:workspace_users,
                                                  :find_by).with(user:).and_return(workspace_user)
      end

      it "returns role permissions" do
        expect(policy.send(:role_permissions)).to eq(workspace_user.role.policies["permissions"])
      end
    end

    context "when user does not have a role in the workspace" do
      before do
        allow(workspace).to receive_message_chain(:workspace_users,
                                                  :find_by).with(user:).and_return(nil)
      end
      it "returns an empty hash" do
        expect(policy.send(:role_permissions)).to eq({})
      end
    end
  end

  describe "#permitted?" do
    it "returns true for permitted action" do
      expect(policy.send(:permitted?, :read, :connector)).to be_truthy
    end

    it "returns false for non-permitted action" do
      expect(policy.send(:permitted?, :create, :connector)).to be_truthy
    end
  end

  describe "#admin?" do
    it "returns true when user is admin in the workspace" do
      allow(workspace).to receive_message_chain(:workspace_users,
                                                :find_by).with(user:).and_return(workspace_user)
      allow(workspace_user).to receive(:admin?).and_return(true)
      expect(policy.send(:admin?)).to be_truthy
    end

    it "returns false when user is not admin in the workspace" do
      allow(workspace).to receive_message_chain(:workspace_users,
                                                :find_by).with(user:).and_return(nil)
      expect(policy.send(:admin?)).to be_falsey
    end
  end
end
