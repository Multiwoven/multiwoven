# frozen_string_literal: true

# == Schema Information
#
# Table name: workspaces
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  status     :string
#  api_key    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "rails_helper"

RSpec.describe Workspace, type: :model do
  # Create a Workspace with an associated Organization before testing
  subject { create(:workspace) }

  context "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_inclusion_of(:status).in_array(%w[active inactive pending]) }
  end

  context "associations" do
    it { should have_many(:connectors).dependent(:nullify) }
    it { should have_many(:models).dependent(:nullify) }
    it { should have_many(:catalogs).dependent(:nullify) }
    it { should have_many(:syncs).dependent(:nullify) }
    it { should have_many(:data_apps).dependent(:nullify) }
    it { should have_many(:data_app_sessions).dependent(:nullify) }
    it { should have_many(:audit_logs).dependent(:nullify) }
    it { should have_many(:custom_visual_component_files).dependent(:nullify) }
    it { should have_many(:message_feedbacks).dependent(:nullify) }
    it { should have_many(:chat_messages).dependent(:nullify) }
    it { should have_many(:sso_configurations).through(:organization) }
    it { should belong_to(:organization) }
    it { should have_many(:workflows).dependent(:destroy) }
    it { should have_many(:workflow_runs).dependent(:destroy) }
    it { should have_many(:workflow_integrations).dependent(:nullify) }
<<<<<<< HEAD
=======
    it { should have_many(:hosted_data_stores).dependent(:nullify) }
    it { should have_many(:knowledge_bases).dependent(:nullify) }
    it { should have_many(:tools).dependent(:destroy) }
    it { should have_many(:llm_routing_logs).dependent(:destroy) }
    it { should have_many(:llm_usage_logs).dependent(:destroy) }
>>>>>>> 6f1a6fb16 (chore(CE): Add LLM Usage Log (#1649))
  end

  context "before_validation callbacks" do
    it "generates slug, workspace_id, and status before validation on create" do
      workspace = described_class.new(name: "Example Workspace")
      workspace.valid?
      expect(workspace.slug).to be_present
      expect(workspace.status).to eq("pending")
    end

    it "generates api_key before validation on create" do
      workspace = described_class.new(name: "Example Workspace")
      workspace.valid?
      expect(workspace.api_key).to be_present
    end
  end

  describe "#verified_admin_user_emails" do
    it "returns only admin users" do
      workspace = create(:workspace)
      workspace_user_admin = create(:workspace_user, workspace:, user: create(:user, confirmed_at: Time.zone.now),
                                                     role: create(:role, :admin))
      create(:workspace_user, workspace:, user: create(:user), role: create(:role, :member))
      verified_admin_user_emails = workspace.verified_admin_user_emails
      expect(verified_admin_user_emails).to eq([workspace_user_admin.user.email])
    end
  end

  describe("active_alerts?") do
    let(:workspace) { create(:workspace) }

    it "returns false if not alerts are present for the current workspace" do
      expect(workspace.active_alerts?).to be(false)
    end

    it "returns true if alerts are present for the current workspace" do
      create(:alert, workspace:, alert_sync_success: true)
      expect(workspace.active_alerts?).to be(true)
    end
  end

  describe "workflow runs" do
    let(:workspace) { create(:workspace) }
    let(:workflow) { create(:workflow, workspace:) }

    it "can have multiple workflow runs" do
      run1 = create(:workflow_run, workspace:, workflow:)
      run2 = create(:workflow_run, workspace:, workflow:)
      run3 = create(:workflow_run, workspace:, workflow:)

      expect(workspace.workflow_runs).to include(run1, run2, run3)
      expect(workspace.workflow_runs.count).to eq(3)
    end

    it "destroys workflows and their workflow runs when workspace is deleted" do
      run1 = create(:workflow_run, workspace:, workflow:)
      run2 = create(:workflow_run, workspace:, workflow:)

      # Delete the workspace
      workspace.destroy

      # Workflows should be destroyed
      expect(Agents::Workflow.exists?(workflow.id)).to be false

      # Workflow runs should also be destroyed (due to workflow's dependent: :destroy)
      expect(Agents::WorkflowRun.exists?(run1.id)).to be false
      expect(Agents::WorkflowRun.exists?(run2.id)).to be false
    end
  end
end
