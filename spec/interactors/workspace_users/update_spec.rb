# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkspaceUsers::Update, type: :interactor do
  let!(:workspace_user) { create(:workspace_user) }

  describe ".call" do
    subject(:result) { described_class.call(id: workspace_user.id, role: new_role) }

    context "when given valid parameters" do
      let(:new_role) { "viewer" } # Assuming 'admin' is a valid role, adjust accordingly.

      it "succeeds" do
        expect(result).to be_success
      end

      it "updates the WorkspaceUser role" do
        expect { result }.to change { workspace_user.reload.role }.from(workspace_user.role).to(new_role)
      end
    end

    context "when given invalid parameters" do
      let(:new_role) { "invalid_role" } # Adjust this to an invalid role for your setup.

      it "fails" do
        expect(result).to be_failure
      end

      it "does not update the WorkspaceUser role" do
        expect { result }.not_to(change { workspace_user.reload.role })
      end

      it "provides a proper error message" do
        expect(result.errors).to include("Role is not included in the list") # Adjust this error message based on your model's validation message.
      end
    end

    context "when provided an invalid WorkspaceUser ID" do
      subject(:result_with_invalid_id) { described_class.call(id: -1, role: "admin") }

      it "fails" do
        expect(result_with_invalid_id).to be_failure
      end

      it "returns a not found error" do
        expect(result_with_invalid_id.errors).to include("WorkspaceUser not found")
      end
    end
  end
end
