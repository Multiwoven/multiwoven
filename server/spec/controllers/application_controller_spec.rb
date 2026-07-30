# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.users.first }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "#current_workspace" do
    context "when Workspace-Id header is present and valid" do
      before do
        request.headers["Workspace-Id"] = workspace.id
      end

      it "returns the current workspace" do
        expect(controller.send(:current_workspace)).to eq(workspace)
      end
    end

    context "when Workspace-Id header is present but invalid" do
      before do
        request.headers["Workspace-Id"] = "invalid_id"
      end

      it 'raises a StandardError with message containing "Workspace not found"' do
        expect { controller.send(:current_workspace) }.to raise_error(StandardError, /Workspace not found/)
      end
    end

    context "when Workspace-Id header is not present" do
      it 'raises a StandardError with message containing "Workspace not found"' do
        expect { controller.send(:current_workspace) }.to raise_error(StandardError, /Workspace not found/)
      end
    end

    context "when Workspace-Id header is present but invalid" do
      before do
        request.headers["Workspace-Id"] = "invalid_id"
      end

      it "includes workspace_id, user_id, and path in the error message" do
        expect { controller.send(:current_workspace) }.to raise_error(StandardError) do |error|
          expect(error.message).to include("workspace_id=")
          expect(error.message).to include("user_id=#{user.id}")
          expect(error.message).to include("path=")
        end
      end
    end
  end

  describe "#eula_required?" do
    context "when current_workspace raises an error" do
      it "returns false" do
        allow(controller).to receive(:current_workspace).and_raise(StandardError, "Workspace not found")
        expect(controller.send(:eula_required?)).to be false
      end
    end

    context "when organization has no eulas" do
      before do
        request.headers["Workspace-Id"] = workspace.id
        allow(workspace.organization).to receive_message_chain(:eulas, :enabled, :exists?).and_return(false)
        allow(controller).to receive(:current_organization).and_return(workspace.organization)
      end

      it "returns false" do
        expect(controller.send(:eula_required?)).to be false
      end
    end
  end

  describe "#ensure_eula_accepted" do
    context "when workspace is not found" do
      it "does not raise and allows the request to continue" do
        allow(controller).to receive(:current_workspace).and_raise(StandardError, "Workspace not found")
        expect { controller.send(:ensure_eula_accepted) }.not_to raise_error
      end
    end
  end
end
