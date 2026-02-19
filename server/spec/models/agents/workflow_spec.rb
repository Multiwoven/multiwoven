# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::Workflow, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
    it { should have_many(:components).dependent(:destroy) }
    it { should have_many(:edges).dependent(:destroy) }
    it { should have_many(:workflow_runs).dependent(:destroy) }
    it { should have_one(:workflow_integration).dependent(:destroy) }
    it { should have_many(:versions) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values(draft: 0, published: 1) }
    it {
      should define_enum_for(:trigger_type).with_values(website_chatbot: 0, chat_assistant: 1, scheduled: 2,
                                                        api_trigger: 3, slack: 4)
    }
  end

  describe "validations" do
    subject { build(:workflow) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:workspace_id).case_insensitive }
    it { should validate_uniqueness_of(:token).allow_nil }
  end

  describe "default scope" do
    let(:workspace) { create(:workspace) }
    let!(:workflow1) { create(:workflow, workspace:, name: "Workflow 1", updated_at: 1.day.ago) }
    let!(:workflow2) { create(:workflow, workspace:, name: "Workflow 2", updated_at: 2.days.ago) }
    let!(:workflow3) { create(:workflow, workspace:, name: "Workflow 3", updated_at: 3.hours.ago) }

    it "orders by updated_at in descending order" do
      result = Agents::Workflow.all
      expect(result.to_a).to eq([workflow3, workflow1, workflow2])
    end

    it "can be overridden with explicit order" do
      result = Agents::Workflow.unscoped.order(:name)
      expect(result.map(&:name)).to eq(["Workflow 1", "Workflow 2", "Workflow 3"])
    end
  end

  describe "configuration storage" do
    let(:workflow) { create(:workflow) }

    it "stores configuration as JSON" do
      config_data = { "api_key" => "sk-xxx", "endpoint" => "https://api.example.com" }
      workflow.configuration = config_data
      workflow.save
      workflow.reload
      expect(workflow.configuration).to eq(config_data)
    end
  end

  describe "token generation" do
    it "generates token only when workflow is published" do
      workflow = create(:workflow)
      expect(workflow.token).to be_nil

      workflow.published!
      expect(workflow.token).to be_present
      expect(workflow.token.length).to eq(32) # 16 bytes in hex = 32 characters
    end

    it "does not generate token when workflow is in draft" do
      workflow = create(:workflow)
      expect(workflow.token).to be_nil

      workflow.save
      expect(workflow.token).to be_nil
    end

    it "generates unique tokens for different workflows" do
      workflow1 = create(:workflow)
      workflow2 = create(:workflow)

      workflow1.published!
      workflow2.published!

      expect(workflow1.token).to be_present
      expect(workflow2.token).to be_present
      expect(workflow1.token).not_to eq(workflow2.token)
    end
  end

  describe "workflow runs" do
    let(:workflow) { create(:workflow) }

    it "can have multiple workflow runs" do
      run1 = create(:workflow_run, workflow:)
      run2 = create(:workflow_run, workflow:)
      run3 = create(:workflow_run, workflow:)

      expect(workflow.workflow_runs).to include(run1, run2, run3)
      expect(workflow.workflow_runs.count).to eq(3)
    end

    it "deletes all workflow runs when workflow is deleted" do
      run1 = create(:workflow_run, workflow:)
      run2 = create(:workflow_run, workflow:)

      expect do
        workflow.destroy
      end.to change { Agents::WorkflowRun.count }.by(-2)

      expect(Agents::WorkflowRun.exists?(run1.id)).to be false
      expect(Agents::WorkflowRun.exists?(run2.id)).to be false
    end
  end
<<<<<<< HEAD
=======

  describe "#accessible_by?" do
    let(:workspace) { create(:workspace) }
    let(:workflow) { create(:workflow, workspace:) }
    let(:admin_role) { create(:role, :admin) }
    let(:member_role) { create(:role, :member) }
    let(:viewer_role) { create(:role, :viewer) }
    let(:admin_user) { create(:user, email: "admin@example.com") }
    let(:member_user) { create(:user, email: "member@example.com") }
    let(:viewer_user) { create(:user, email: "viewer@example.com") }
    let(:other_user) { create(:user, email: "other@example.com") }

    before do
      create(:workspace_user, workspace:, user: admin_user, role: admin_role)
      create(:workspace_user, workspace:, user: member_user, role: member_role)
      create(:workspace_user, workspace:, user: viewer_user, role: viewer_role)
    end

    context "when access_control_enabled is false" do
      it "returns true for any user" do
        workflow.update!(access_control_enabled: false)
        expect(workflow.accessible_by?(admin_user)).to be true
        expect(workflow.accessible_by?(member_user)).to be true
        expect(workflow.accessible_by?(other_user)).to be true
      end
    end

    context "when access_control_enabled is true" do
      before do
        workflow.update!(access_control_enabled: true)
      end

      context "when both allowed_role_ids and allowed_users are empty" do
        it "returns true for any user" do
          workflow.update!(access_control: {})
          expect(workflow.accessible_by?(admin_user)).to be true
          expect(workflow.accessible_by?(member_user)).to be true
          expect(workflow.accessible_by?(other_user)).to be true
        end
      end

      context "when allowed_role_ids is specified" do
        it "returns true if user's role ID is in allowed_role_ids" do
          workflow.update!(
            access_control: {
              "allowed_role_ids" => [admin_role.id, member_role.id]
            }
          )
          expect(workflow.accessible_by?(admin_user)).to be true
          expect(workflow.accessible_by?(member_user)).to be true
        end

        it "returns false if user's role ID is not in allowed_role_ids" do
          workflow.update!(
            access_control: {
              "allowed_role_ids" => [admin_role.id]
            }
          )
          expect(workflow.accessible_by?(member_user)).to be false
          expect(workflow.accessible_by?(viewer_user)).to be false
        end

        it "returns false if user has no role in the workspace" do
          workflow.update!(
            access_control: {
              "allowed_role_ids" => [admin_role.id]
            }
          )
          expect(workflow.accessible_by?(other_user)).to be false
        end

        it "handles string role IDs from frontend correctly" do
          # Frontend may submit role IDs as strings, which get persisted as strings in JSONB
          workflow.update!(
            access_control: {
              "allowed_role_ids" => [admin_role.id.to_s, member_role.id.to_s]
            }
          )
          expect(workflow.accessible_by?(admin_user)).to be true
          expect(workflow.accessible_by?(member_user)).to be true
          expect(workflow.accessible_by?(viewer_user)).to be false
        end
      end

      context "when allowed_users is specified" do
        it "returns true if user's email is in allowed_users" do
          workflow.update!(
            access_control: {
              "allowed_users" => [admin_user.email, member_user.email]
            }
          )
          expect(workflow.accessible_by?(admin_user)).to be true
          expect(workflow.accessible_by?(member_user)).to be true
        end

        it "returns false if user's email is not in allowed_users" do
          workflow.update!(
            access_control: {
              "allowed_users" => [admin_user.email]
            }
          )
          expect(workflow.accessible_by?(member_user)).to be false
          expect(workflow.accessible_by?(other_user)).to be false
        end
      end

      context "when both allowed_role_ids and allowed_users are specified" do
        it "returns true if user matches either role ID or email" do
          workflow.update!(
            access_control: {
              "allowed_role_ids" => [admin_role.id],
              "allowed_users" => [member_user.email]
            }
          )
          expect(workflow.accessible_by?(admin_user)).to be true # matches role
          expect(workflow.accessible_by?(member_user)).to be true # matches email
        end

        it "returns false if user matches neither role ID nor email" do
          workflow.update!(
            access_control: {
              "allowed_role_ids" => [admin_role.id],
              "allowed_users" => [admin_user.email]
            }
          )
          expect(workflow.accessible_by?(viewer_user)).to be false
          expect(workflow.accessible_by?(other_user)).to be false
        end
      end

      context "with edge cases" do
        it "handles nil access_control gracefully" do
          # access_control has NOT NULL constraint, so we test with empty hash instead
          workflow.update!(access_control: {})
          expect(workflow.accessible_by?(admin_user)).to be true
        end

        it "handles empty arrays in access_control" do
          workflow.update!(
            access_control: {
              "allowed_role_ids" => [],
              "allowed_users" => []
            }
          )
          expect(workflow.accessible_by?(admin_user)).to be true
        end

        it "handles missing keys in access_control hash" do
          workflow.update!(
            access_control: {
              "allowed_role_ids" => [admin_role.id]
            }
          )
          expect(workflow.accessible_by?(admin_user)).to be true
          expect(workflow.accessible_by?(member_user)).to be false
        end
      end
    end
  end

  describe "#latest_published_version" do
    let(:workspace) { create(:workspace) }

    context "when the workflow has no versions" do
      let(:workflow) { create(:workflow, workspace:) }

      it "returns nil" do
        expect(workflow.versions).to be_empty
        expect(workflow.latest_published_version).to be_nil
      end
    end

    context "when the workflow has versions but none are published" do
      let(:workflow) { create(:workflow, workspace:, status: :draft) }

      before do
        workflow.update!(version_number: 1)
        workflow.paper_trail_event = "draft"
        version = workflow.paper_trail.save_with_version
        version.update!(version_number: 1)
      end

      it "returns nil" do
        expect(workflow.versions.where(event: "published")).to be_empty
        expect(workflow.latest_published_version).to be_nil
      end
    end

    context "when the workflow has one published version" do
      let(:workflow) { create(:workflow, workspace:, name: "Published Workflow", status: :published) }

      before do
        workflow.update!(version_number: 1)
        workflow.paper_trail_event = "published"
        version = workflow.paper_trail.save_with_version
        version.update!(version_number: 1)
      end

      it "returns the reified workflow from that version" do
        result = workflow.latest_published_version

        expect(result).to be_a(Agents::Workflow)
        expect(result.id).to eq(workflow.id)
        expect(result.name).to eq("Published Workflow")
        expect(result.status).to eq("published")
      end

      it "returns a workflow that responds to components and edges without error" do
        result = workflow.latest_published_version

        expect(result.components).to eq([])
        expect(result.edges).to eq([])
      end
    end

    context "when the workflow has multiple published versions" do
      let(:workflow) { create(:workflow, workspace:, name: "Original", status: :published) }

      before do
        workflow.update!(version_number: 1)
        workflow.paper_trail_event = "published"
        v1 = workflow.paper_trail.save_with_version
        v1.update!(version_number: 1)

        workflow.update!(name: "Updated", version_number: 2)
        workflow.paper_trail_event = "published"
        v2 = workflow.paper_trail.save_with_version
        v2.update!(version_number: 2)
      end

      it "returns the version with the highest version_number" do
        result = workflow.latest_published_version

        expect(result).to be_a(Agents::Workflow)
        expect(result.name).to eq("Updated")
        expect(result.id).to eq(workflow.id)
      end
    end
  end
>>>>>>> 578f80e42 (feat(CE): database migrations for workflow versioning (#1598))
end
