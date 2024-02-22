# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkspaceUsers::List, type: :interactor do
  let(:workspace) { create(:workspace) }
  # Creates 3 workspace_users associated with the workspace
  let!(:workspace_users) do
    create_list(:workspace_user, 3, workspace:)
  end
  describe ".call" do
    subject(:result) { described_class.call(workspace:) }

    it "succeeds" do
      expect(result).to be_success
    end

    it "returns a list of workspace users for the given workspace" do
      WorkspaceUser.delete_all # Manually clear all WorkspaceUser records
      workspace_users = create_list(:workspace_user, 3, workspace:)
      expect(result.workspace_users.count).to eq(3)
      expect(result.workspace_users).to match_array(workspace_users)
    end

    it "eager loads users" do
      expect(result.workspace_users).to all(satisfy { |wu| wu.association(:user).loaded? })
    end
  end
end
