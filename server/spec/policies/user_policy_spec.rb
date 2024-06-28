# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let(:workspace_user) { workspace.workspace_users.first }
  let(:record) { user }
  let(:context) { double("Context", user:, workspace:) }
  let(:policy) { described_class.new(context, record) }

  describe "#me?" do
    it "returns true" do
      expect(policy.me?).to be_truthy
    end
  end
end
