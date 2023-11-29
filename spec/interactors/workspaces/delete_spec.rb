# frozen_string_literal: true

require "rails_helper"

RSpec.describe Workspaces::Delete, type: :interactor do
  let!(:user) { create(:user) } # using let! to force immediate execution
  let!(:workspace) { create(:workspace) } # using let! to force immediate execution

  describe ".call" do
    before do
      # Link the user and the workspace
      create(:workspace_user, workspace:, user:, role: "admin")
    end

    context "when the delete is successful" do
      it "succeeds" do
        context = Workspaces::Delete.call(user:, id: workspace.id)
        expect(context).to be_a_success
      end

      it "deletes the workspace" do
        Workspaces::Delete.call(user:, id: workspace.id)
        expect { workspace.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
