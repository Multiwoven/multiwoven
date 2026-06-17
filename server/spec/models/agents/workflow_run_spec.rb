# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::WorkflowRun, type: :model do
  describe "associations" do
    it { should belong_to(:workflow).class_name("Agents::Workflow") }
    it { should belong_to(:workspace) }
    it { should have_one(:workflow_log).class_name("Agents::WorkflowLog").dependent(:destroy) }
<<<<<<< HEAD
=======
    it { should have_many(:llm_routing_logs).dependent(:destroy) }
    it { should have_many(:llm_usage_logs).dependent(:destroy) }
>>>>>>> 6f1a6fb16 (chore(CE): Add LLM Usage Log (#1649))
  end

  describe "validations" do
    it { should validate_presence_of(:workflow_id) }
    it { should validate_presence_of(:workspace_id) }
    it { should validate_presence_of(:status) }
  end

  describe "defaults" do
    it "sets default status to pending" do
      workflow_run = Agents::WorkflowRun.new
      expect(workflow_run.status).to eq("pending")
    end
  end

  describe "scopes" do
    let!(:pending_run) { create(:workflow_run, status: "pending") }
    let!(:in_progress_run) { create(:workflow_run, status: "in_progress") }
    let!(:completed_run) { create(:workflow_run, status: "completed") }
    let!(:failed_run) { create(:workflow_run, status: "failed") }

    describe ".active" do
      it "returns only pending and in_progress runs" do
        expect(Agents::WorkflowRun.active).to include(pending_run, in_progress_run)
        expect(Agents::WorkflowRun.active).not_to include(completed_run, failed_run)
      end
    end
  end

  describe "state machine" do
    let(:workflow_run) { create(:workflow_run) }

    describe "initial state" do
      it "starts with pending status" do
        expect(workflow_run).to be_pending
      end
    end

    describe "start event" do
      it "transitions from pending to in_progress" do
        expect(workflow_run).to be_pending
        workflow_run.start!
        expect(workflow_run).to be_in_progress
      end

      it "allows transition from in_progress to in_progress" do
        workflow_run.start!
        expect(workflow_run).to be_in_progress
        workflow_run.start!
        expect(workflow_run).to be_in_progress
      end

      it "does not allow transition from completed state" do
        workflow_run.start!
        workflow_run.complete!
        expect { workflow_run.start! }.to raise_error(AASM::InvalidTransition)
      end

      it "does not allow transition from failed state" do
        workflow_run.fail!
        expect { workflow_run.start! }.to raise_error(AASM::InvalidTransition)
      end

      it "does not allow transition from cancelled state" do
        workflow_run.cancel!
        expect { workflow_run.start! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe "complete event" do
      before { workflow_run.start! }

      it "transitions from in_progress to completed" do
        expect(workflow_run).to be_in_progress
        workflow_run.complete!
        expect(workflow_run).to be_completed
      end

      it "does not allow transition from other states" do
        workflow_run.complete!
        expect { workflow_run.complete! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe "fail event" do
      it "transitions from pending to failed" do
        expect(workflow_run).to be_pending
        workflow_run.fail!
        expect(workflow_run).to be_failed
      end

      it "transitions from in_progress to failed" do
        workflow_run.start!
        expect(workflow_run).to be_in_progress
        workflow_run.fail!
        expect(workflow_run).to be_failed
      end

      it "does not allow transition from terminal states" do
        workflow_run.fail!
        expect { workflow_run.fail! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe "cancel event" do
      it "transitions from pending to cancelled" do
        expect(workflow_run).to be_pending
        workflow_run.cancel!
        expect(workflow_run).to be_cancelled
      end

      it "transitions from in_progress to cancelled" do
        workflow_run.start!
        expect(workflow_run).to be_in_progress
        workflow_run.cancel!
        expect(workflow_run).to be_cancelled
      end

      it "does not allow transition from terminal states" do
        workflow_run.cancel!
        expect { workflow_run.cancel! }.to raise_error(AASM::InvalidTransition)
      end
    end
  end

  describe "instance methods" do
    let(:workflow_run) { create(:workflow_run) }

    describe "#may_start?" do
      it "returns true for pending state" do
        expect(workflow_run.may_start?).to be true
      end

      it "returns true for in_progress state" do
        workflow_run.start!
        expect(workflow_run.may_start?).to be true
      end

      it "returns false for completed state" do
        workflow_run.start!
        workflow_run.complete!
        expect(workflow_run.may_start?).to be false
      end

      it "returns false for failed state" do
        workflow_run.fail!
        expect(workflow_run.may_start?).to be false
      end

      it "returns false for cancelled state" do
        workflow_run.cancel!
        expect(workflow_run.may_start?).to be false
      end
    end

    describe "#update_success" do
      before { workflow_run.start! }

      it "transitions to completed state" do
        workflow_run.update_success
        expect(workflow_run).to be_completed
      end
    end

    describe "#update_failure!" do
      it "transitions to failed state" do
        workflow_run.update_failure!
        expect(workflow_run).to be_failed
      end
    end

    describe "#terminal_status?" do
      it "returns true for completed state" do
        workflow_run.start!
        workflow_run.complete!
        expect(workflow_run.terminal_status?).to be true
      end

      it "returns true for failed state" do
        workflow_run.fail!
        expect(workflow_run.terminal_status?).to be true
      end

      it "returns false for pending state" do
        expect(workflow_run.terminal_status?).to be false
      end

      it "returns false for in_progress state" do
        workflow_run.start!
        expect(workflow_run.terminal_status?).to be false
      end

      it "returns false for cancelled state" do
        workflow_run.cancel!
        expect(workflow_run.terminal_status?).to be true
      end
    end

    describe "#duration_in_seconds" do
      it "calculates duration correctly" do
        workflow_run.update!(created_at: 1.hour.ago, updated_at: Time.current)
        expect(workflow_run.duration_in_seconds).to be_within(5).of(3600)
      end

      it "returns 0 for new records" do
        expect(workflow_run.duration_in_seconds).to eq(0)
      end
    end
  end

  describe "jsonb fields" do
    let(:workflow_run) { create(:workflow_run) }

    it "can store and retrieve inputs" do
      inputs = { "key1" => "value1", "key2" => { "nested" => "value" } }
      workflow_run.inputs = inputs
      workflow_run.save!

      expect(workflow_run.reload.inputs).to eq(inputs)
    end

    it "can store and retrieve outputs" do
      outputs = { "result" => "success", "data" => [1, 2, 3] }
      workflow_run.outputs = outputs
      workflow_run.save!

      expect(workflow_run.reload.outputs).to eq(outputs)
    end

    it "defaults inputs and outputs to empty hash" do
      expect(workflow_run.inputs).to eq({})
      expect(workflow_run.outputs).to eq({})
    end
  end

  describe "error handling" do
    let(:workflow_run) { create(:workflow_run) }

    it "can store error messages" do
      error_message = "Something went wrong during execution"
      workflow_run.error_message = error_message
      workflow_run.save!

      expect(workflow_run.reload.error_message).to eq(error_message)
    end
  end

  describe "temporal workflow id" do
    let(:workflow_run) { create(:workflow_run) }

    it "can store temporal workflow id" do
      temporal_id = "workflow-12345"
      workflow_run.temporal_workflow_id = temporal_id
      workflow_run.save!

      expect(workflow_run.reload.temporal_workflow_id).to eq(temporal_id)
    end
  end

  describe "tokens used" do
    let(:workflow_run) { create(:workflow_run) }
    let(:connector) { create(:connector, workspace: workflow_run.workspace, connector_name: "OpenAI") }

    it "calculates tokens used correctly" do
      component = create(:component, workflow: workflow_run.workflow, workspace: workflow_run.workspace)
      workflow_run.llm_usage_logs.create!(
        workspace: workflow_run.workspace,
        workflow_run:,
        component_id: component.id,
        connector_id: connector.id.to_s,
        prompt_hash: "test_prompt_hash",
        estimated_input_tokens: 100,
        estimated_output_tokens: 200,
        selected_model: "gpt-4o-mini",
        provider: "openai"
      )
      expect(workflow_run.tokens_used).to eq(300)
    end
  end
end
