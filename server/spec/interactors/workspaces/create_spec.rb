# frozen_string_literal: true

# spec/interactors/workspaces/create_spec.rb

require "rails_helper"

RSpec.describe Workspaces::Create, type: :interactor do
  let!(:role) { create(:role, :admin) }
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:valid_attributes) do
    { name: "My Workspace", slug: "my-workspace", status: "active", organization: }
  end
  let(:invalid_attributes) { { name: nil, slug: nil, status: "invalid", organization: nil } }
  let(:context) { Workspaces::Create.call(workspace_params: valid_attributes, user:) }
  let(:context_fail) { Workspaces::Create.call(workspace_params: invalid_attributes, user:) }

  describe ".call" do
    context "when given valid attributes" do
      it "succeeds" do
        expect(context).to be_a_success
      end

      it "provides the workspace" do
        expect(context.workspace).to be_present
        expect(context.workspace).to be_an_instance_of(Workspace)
      end

      it "associates the workspace with the user" do
        expect(user.workspaces).to include(context.workspace)
      end
    end

    context "when given invalid attributes" do
      it "fails" do
        expect(context_fail).to be_a_failure
      end
    end
  end
end
