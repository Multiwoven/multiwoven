# frozen_string_literal: true

# spec/interactors/workspaces/update_spec.rb

require "rails_helper"

RSpec.describe Workspaces::Update, type: :interactor do
  let(:user) { create(:user) }
  let(:workspace) { create(:workspace) }
  let(:new_name) { "New Workspace" }
  let(:context) { Workspaces::Update.call(id: workspace.id, user:, workspace_params: { name: new_name }) }

  describe ".call" do
    before do
      create(:workspace_user, workspace:, user:, role: create(:role, :admin))
    end

    context "when the update is successful" do
      it "succeeds" do
        expect(context).to be_a_success
      end

      it "updates the workspace name" do
        expect(context.workspace.name).to eq(new_name)
      end
    end

    context "when the update fails" do
      let(:context) { Workspaces::Update.call(id: workspace.id, user:, workspace_params: { name: nil }) }

      it "fails" do
        expect(context).to be_a_failure
      end

      it "provides a failure message" do
        expect(context.workspace.errors[:name]).to include("can't be blank")
      end
    end

    context "when slug is missing and the update is successful" do
      it "succeeds" do
        workspace.slug = ""
        context = Workspaces::Update.call(id: workspace.id, user:, workspace_params: { name: new_name })
        expect(context).to be_a_success
        expect(context.workspace.name).to eq(new_name)
      end
    end

    context "when workspace belongs to another user (IDOR)" do
      let(:other_user) { create(:user) }

      it "fails and does not update the workspace" do
        original_name = workspace.name
        result = Workspaces::Update.call(id: workspace.id, user: other_user, workspace_params: { name: "Hacked" })

        expect(result).to be_a_failure
        expect(workspace.reload.name).to eq(original_name)
      end
    end
  end
end
