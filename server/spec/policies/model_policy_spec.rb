# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModelPolicy, type: :policy do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let(:workspace_user) { workspace.workspace_users.first }
  let(:model) { create(:model) }
  let(:record) { model }
  let(:context) { double("Context", user:, workspace:) }
  let(:policy) { described_class.new(context, record) }

  describe "#index?" do
    it "returns true when user is permitted to read models" do
      allow(policy).to receive(:permitted?).with(:read, :model).and_return(true)
      expect(policy.index?).to be_truthy
    end

    it "returns false when user is not permitted to read models" do
      allow(policy).to receive(:permitted?).with(:read, :model).and_return(false)
      expect(policy.index?).to be_falsey
    end
  end

  describe "#show?" do
    it "returns true when user is permitted to read models" do
      allow(policy).to receive(:permitted?).with(:read, :model).and_return(true)
      expect(policy.show?).to be_truthy
    end

    it "returns false when user is not permitted to read models" do
      allow(policy).to receive(:permitted?).with(:read, :model).and_return(false)
      expect(policy.show?).to be_falsey
    end
  end

  describe "#create?" do
    it "returns true when user is permitted to create models" do
      allow(policy).to receive(:permitted?).with(:create, :model).and_return(true)
      expect(policy.create?).to be_truthy
    end

    it "returns false when user is not permitted to create models" do
      allow(policy).to receive(:permitted?).with(:create, :model).and_return(false)
      expect(policy.create?).to be_falsey
    end
  end

  describe "#update?" do
    it "returns true when user is permitted to update models" do
      allow(policy).to receive(:permitted?).with(:update, :model).and_return(true)
      expect(policy.update?).to be_truthy
    end

    it "returns false when user is not permitted to update models" do
      allow(policy).to receive(:permitted?).with(:update, :model).and_return(false)
      expect(policy.update?).to be_falsey
    end
  end

  describe "#destroy?" do
    it "returns true when user is permitted to delete models" do
      allow(policy).to receive(:permitted?).with(:delete, :model).and_return(true)
      expect(policy.destroy?).to be_truthy
    end

    it "returns false when user is not permitted to delete models" do
      allow(policy).to receive(:permitted?).with(:delete, :model).and_return(false)
      expect(policy.destroy?).to be_falsey
    end
  end

  describe "#configurations?" do
    it "returns true when user is permitted to read models" do
      allow(policy).to receive(:permitted?).with(:read, :model).and_return(true)
      expect(policy.configurations?).to be_truthy
    end

    it "returns false when user is not permitted to read models" do
      allow(policy).to receive(:permitted?).with(:read, :model).and_return(false)
      expect(policy.configurations?).to be_falsey
    end
  end
end
