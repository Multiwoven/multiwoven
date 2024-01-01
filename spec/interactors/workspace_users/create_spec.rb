# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkspaceUsers::Create, type: :interactor do
  let(:workspace) { Workspace.new(id: 1) }

  describe ".call" do
    subject(:result) { described_class.call(workspace:, user_params:) }

    context "when given valid parameters" do
      let(:user_params) { { name: "Test User", email: "test@example.com", role: "member" } }

      before do
        allow(User).to receive(:find_by).and_return(nil)
        allow(User).to receive(:create!).and_return(User.new(email: "test@example.com"))
        allow(WorkspaceUser).to receive(:new).and_return(WorkspaceUser.new(user: User.new(email: "test@example.com"),
                                                                           workspace:, role: "member"))
        allow_any_instance_of(WorkspaceUser).to receive(:save).and_return(true)
      end

      it "succeeds" do
        expect(result).to be_success
      end

      it "creates a WorkspaceUser" do
        result
        workspace_user = result.workspace_user

        expect(workspace_user).not_to be_nil
        expect(workspace_user.user.email).to eq("test@example.com")
        expect(workspace_user.workspace).to eq(workspace)
        expect(workspace_user.role).to eq("member")
      end
    end

    context "when given invalid parameters" do
      let(:user_params) { { name: "", email: "", role: "member" } }

      before do
        allow(User).to receive(:find_by).and_return(nil)
        allow(User).to receive(:create!).and_return(User.new(email: "test@example.com"))
        allow(WorkspaceUser).to receive(:new).and_return(WorkspaceUser.new(user: User.new(email: "test@example.com"),
                                                                           workspace:, role: "member"))
        allow_any_instance_of(WorkspaceUser).to receive(:save).and_return(true)
      end

      it "fails" do
        expect(result).to be_failure
      end

      it "does not create a WorkspaceUser" do
        expect(result.workspace_user).to be_nil
      end

      it "does not create a User" do
        expect(User.find_by(email: user_params[:email])).to be_nil
      end
    end
  end
end
