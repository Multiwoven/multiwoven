# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpendingLimitPolicy, type: :policy do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let(:workspace_user) { workspace.workspace_users.first }
  let(:record) { workspace }
  let(:context) { CurrentContext.new(user:, workspace:) }
  let(:policy) { described_class.new(context, record) }

  describe "#index?" do
    it "returns true when user is permitted to read spending limits" do
      allow(policy).to receive(:permitted?).with(:read, :spending_limit).and_return(true)
      expect(policy.index?).to be_truthy
    end

    it "returns false when user is not permitted to read spending limits" do
      allow(policy).to receive(:permitted?).with(:read, :spending_limit).and_return(false)
      expect(policy.index?).to be_falsey
    end
  end

  describe "#show?" do
    it "returns true when user is permitted to read a spending limit" do
      allow(policy).to receive(:permitted?).with(:read, :spending_limit).and_return(true)
      expect(policy.show?).to be_truthy
    end

    it "returns false when user is not permitted to read a spending limit" do
      allow(policy).to receive(:permitted?).with(:read, :spending_limit).and_return(false)
      expect(policy.show?).to be_falsey
    end
  end

  describe "#create?" do
    it "returns true when user is permitted to create a spending limit" do
      allow(policy).to receive(:permitted?).with(:create, :spending_limit).and_return(true)
      expect(policy.create?).to be_truthy
    end

    it "returns false when user is not permitted to create a spending limit" do
      allow(policy).to receive(:permitted?).with(:create, :spending_limit).and_return(false)
      expect(policy.create?).to be_falsey
    end
  end

  describe "#update?" do
    it "returns true when user is permitted to update a spending limit" do
      allow(policy).to receive(:permitted?).with(:update, :spending_limit).and_return(true)
      expect(policy.update?).to be_truthy
    end

    it "returns false when user is not permitted to update a spending limit" do
      allow(policy).to receive(:permitted?).with(:update, :spending_limit).and_return(false)
      expect(policy.update?).to be_falsey
    end
  end

  describe "#destroy?" do
    it "returns true when user is permitted to delete a spending limit" do
      allow(policy).to receive(:permitted?).with(:delete, :spending_limit).and_return(true)
      expect(policy.destroy?).to be_truthy
    end

    it "returns false when user is not permitted to delete a spending limit" do
      allow(policy).to receive(:permitted?).with(:delete, :spending_limit).and_return(false)
      expect(policy.destroy?).to be_falsey
    end
  end

  describe "the permissions a role actually carries" do
    context "when the role grants every spending limit action" do
      before { workspace_user.update(role: create(:role, :admin)) }

      it "allows reading, creating, updating and deleting" do
        expect(policy.index?).to be_truthy
        expect(policy.show?).to be_truthy
        expect(policy.create?).to be_truthy
        expect(policy.update?).to be_truthy
        expect(policy.destroy?).to be_truthy
      end
    end

    context "when the role only grants read" do
      before { workspace_user.update(role: create(:role, :member)) }

      it "allows reading but refuses every write" do
        expect(policy.index?).to be_truthy
        expect(policy.show?).to be_truthy
        expect(policy.create?).to be_falsey
        expect(policy.update?).to be_falsey
        expect(policy.destroy?).to be_falsey
      end
    end
  end
end
