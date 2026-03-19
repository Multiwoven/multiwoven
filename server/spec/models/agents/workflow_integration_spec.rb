# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::WorkflowIntegration, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:workflow) }
  end

  describe "enums" do
    it { should define_enum_for(:app_type).with_values(slack: 0) }
  end

  describe "validations" do
    subject { build(:workflow_integration) }

    it { should validate_presence_of(:workflow_id) }
    it { should validate_presence_of(:workspace_id) }
    it { should validate_presence_of(:app_type) }
    it { should validate_presence_of(:connection_configuration) }
    it { should validate_presence_of(:metadata) }
  end

  context "validates json schema of configuration" do
    context "validates json schema of workflow integrations for slack" do
      it "returns invalid for workflow integrations for slack without valid configuration" do
        workflow = create(:workflow)
        workflow_integration = Agents::WorkflowIntegration.new(
          workflow_id: workflow.id,
          app_type: :slack,
          workspace_id: workflow.workspace_id,
          connection_configuration: nil
        )
        expect(workflow_integration).not_to be_valid
      end

      it "returns valid for workflow integrations for slack with valid configuration" do
        workflow = create(:workflow)
        workflow_integration = Agents::WorkflowIntegration.new(
          workflow_id: workflow.id,
          app_type: :slack,
          workspace_id: workflow.workspace_id,
          connection_configuration: {
            "client_id": "test_client_id",
            "client_secret": "test_client_secret",
            "signing_signature": "test_signing_signature"
          },
          metadata: {
            "data_app_id": "test_data_app_id",
            "workflow_id": "test_workflow_id",
            "visual_component_id": "test_visual_component_id"
          }
        )
        expect(workflow_integration).to be_valid
      end
    end
  end
end
