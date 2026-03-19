# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::Workflow, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
    it { should have_many(:components).dependent(:destroy) }
    it { should have_many(:edges).dependent(:destroy) }
    it { should have_many(:workflow_runs).dependent(:destroy) }
    it { should have_one(:workflow_integration).dependent(:destroy) }
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
end
