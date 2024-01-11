# frozen_string_literal: true

# spec/interactors/workspaces/update_spec.rb

require "rails_helper"

RSpec.describe Workspaces::Update, type: :interactor do
  let(:user) { create(:user) }
  let(:workspace) { create(:workspace) }
  let(:new_name) { "New Workspace" }
  let(:context) { Workspaces::Update.call(id: workspace.id, user:, workspace_params: { name: new_name }) }

  describe ".call" do
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
  end
end
