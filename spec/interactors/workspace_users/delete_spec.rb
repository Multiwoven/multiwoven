# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkspaceUsers::Delete, type: :interactor do
  let(:workspace_user) { create(:workspace_user) }

  describe ".call" do
    subject(:result) { described_class.call(id: workspace_user.id) }

    context "when a valid workspace_user id is provided" do
      it "succeeds" do
        expect(result).to be_success
      end

      it "deletes the WorkspaceUser" do
        # Explicitly create a WorkspaceUser that will be targeted for deletion
        workspace_user_to_delete = create(:workspace_user)

        # Run the interactor to delete the created WorkspaceUser
        described_class.call(id: workspace_user_to_delete.id)

        # Check that the WorkspaceUser has been deleted
        expect(WorkspaceUser.exists?(workspace_user_to_delete.id)).to be_falsey
      end
    end

    context "when an invalid workspace_user id is provided" do
      let(:invalid_id) { workspace_user.id + 100 }

      it "fails and provides an error message" do
        result = described_class.call(id: invalid_id)
        expect(result).to be_failure
        expect(result.errors).to include("Failed to remove user from workspace")
      end
    end
  end
end
