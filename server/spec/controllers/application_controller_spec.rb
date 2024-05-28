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

      it 'raises a StandardError with message "Workspace not found"' do
        expect { controller.send(:current_workspace) }.to raise_error(StandardError, "Workspace not found")
      end
    end

    context "when Workspace-Id header is not present" do
      it 'raises a StandardError with message "Workspace not found"' do
        expect { controller.send(:current_workspace) }.to raise_error(StandardError, "Workspace not found")
      end
    end
  end
end
