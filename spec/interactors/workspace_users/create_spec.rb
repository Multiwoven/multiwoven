# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkspaceUsers::Create, type: :interactor do
  let(:workspace) { create(:workspace) }
  let(:user_params) { { email: "test@example.com", role: "member" } }

  describe ".call" do
    subject(:result) { described_class.call(workspace:, user_params:) }

    context "when given valid parameters" do
      it "succeeds" do
        expect(result).to be_success
      end

      it "creates a WorkspaceUser" do
        result
        workspace_user = WorkspaceUser.last

        expect(workspace_user.user.email).to eq("test@example.com")
        expect(workspace_user.workspace).to eq(workspace)
        expect(workspace_user.role).to eq("member")
      end
    end

    context "when given invalid parameters" do
      let(:user_params) { { email: "", role: "member" } }

      it "fails" do
        expect(result).to be_failure
      end

      it "does not create a WorkspaceUser" do
        result
        expect(WorkspaceUser.where(workspace:, role: "member")).to be_empty
      end

      it "does not create a User" do
        result
        expect(User.where(email: "")).to be_empty
      end
    end
  end
end
