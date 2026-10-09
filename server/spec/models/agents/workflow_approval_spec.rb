# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::WorkflowApproval, type: :model do
  describe "associations" do
    it { should belong_to(:workflow_run).class_name("Agents::WorkflowRun") }
    it { should belong_to(:workspace) }
    it { should belong_to(:resolved_by).class_name("User").optional }
  end

  describe "validations" do
    it { should validate_presence_of(:workflow_run_id) }
    it { should validate_presence_of(:workspace_id) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:message) }
    it { should validate_presence_of(:temporal_workflow_id) }
    it { should validate_presence_of(:temporal_run_id) }
  end

  describe "enum" do
    it { should define_enum_for(:status).with_values(pending: 0, approved: 1, rejected: 2, timed_out: 3) }
  end

  describe "scopes" do
    let!(:pending_approval) { create(:workflow_approval, :pending) }
    let!(:approved_approval) { create(:workflow_approval, :approved) }
    let!(:rejected_approval) { create(:workflow_approval, :rejected) }
    let!(:timed_out_approval) { create(:workflow_approval, :timed_out) }

    describe ".active" do
      it "returns only pending approvals" do
        expect(described_class.active).to include(pending_approval)
        expect(described_class.active).not_to include(approved_approval, rejected_approval, timed_out_approval)
      end
    end
  end

  describe "factory" do
    it "creates a valid workflow_approval" do
      approval = create(:workflow_approval)
      expect(approval).to be_valid
      expect(approval).to be_pending
    end

    it "creates approved approval" do
      approval = create(:workflow_approval, :approved)
      expect(approval).to be_approved
      expect(approval.resolved_at).to be_present
    end

    it "creates rejected approval" do
      approval = create(:workflow_approval, :rejected)
      expect(approval).to be_rejected
    end

    it "creates timed_out approval" do
      approval = create(:workflow_approval, :timed_out)
      expect(approval).to be_timed_out
    end
  end

  describe "attributes" do
    let(:approval) { create(:workflow_approval) }

    it "stores input_data as jsonb" do
      approval.update!(input_data: { "key" => "value", "nested" => { "a" => 1 } })
      expect(approval.reload.input_data).to eq({ "key" => "value", "nested" => { "a" => 1 } })
    end

    it "stores temporal workflow and run IDs" do
      expect(approval.temporal_workflow_id).to be_present
      expect(approval.temporal_run_id).to be_present
    end

    it "allows optional fields to be nil" do
      approval = create(:workflow_approval, resolved_by: nil, resolution_note: nil, timeout_at: nil)
      expect(approval).to be_valid
    end
  end
end
