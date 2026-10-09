# frozen_string_literal: true

require "rails_helper"

RSpec.describe VisualComponents::CreateVisualComponent, type: :interactor do
  describe ".call" do
    let(:workspace) { create(:workspace) }
    let(:data_app) { create(:data_app, workspace:, visual_components_count: 0) }
    let!(:ai_ml_connector) { create(:connector, workspace:, connector_category: "AI Model") }
    let!(:ai_ml_model) do
      create(:model, query_type: :ai_ml, connector: ai_ml_connector, configuration: { harvesters: [] }, workspace:)
    end
    let!(:workflow) { create(:workflow, workspace:) }
    let(:valid_visual_components_params) do
      [
        { component_type: "doughnut", name: "Sales Pie Chart", configurable_id: ai_ml_model.id.to_s,
          configurable_type: "Model", properties: { color: "blue" } }
      ]
    end

    let(:valid_workflow_visual_components_params) do
      [
        { component_type: "chat_bot", name: "Workflow Chat Bot", configurable_id: workflow.id.to_s,
          configurable_type: "Agents::Workflow", properties: { theme: "dark" } }
      ]
    end

    let(:invalid_visual_components_params) do
      [
        { component_type: "doughnut", name: "Invalid Component", configurable_id: 0, configurable_type: "Model" }
      ]
    end

    let(:invalid_workflow_visual_components_params) do
      [
        { component_type: "chat_bot", name: "Invalid Workflow Component", configurable_id: "invalid-uuid",
          configurable_type: "Agents::Workflow" }
      ]
    end

    context "when all visual components are created successfully with model configurable" do
      it "creates visual components and sets them in the context" do
        result = described_class.call(
          visual_components_params: valid_visual_components_params,
          data_app:,
          workspace:
        )
        expect(result).to be_a_success
        expect(data_app.visual_components.count).to eq(1)
        expect(data_app.visual_components.map(&:name)).to include("Sales Pie Chart")
        expect(data_app.visual_components.first.model).to eq(ai_ml_model)
        expect(data_app.visual_components.first.workflow).to be_nil
      end
    end

    context "when all visual components are created successfully with workflow configurable" do
      it "creates visual components and sets them in the context" do
        result = described_class.call(
          visual_components_params: valid_workflow_visual_components_params,
          data_app:,
          workspace:
        )
        expect(result).to be_a_success
        expect(data_app.visual_components.count).to eq(1)
        expect(data_app.visual_components.map(&:name)).to include("Workflow Chat Bot")
        expect(data_app.visual_components.first.workflow).to eq(workflow)
        expect(data_app.visual_components.first.model).to be_nil
        expect(data_app.visual_components.first.component_type).to eq("chat_bot")
      end
    end

    context "when some visual components fail to be created with model configurable" do
      it "fails and sets the error message in the context" do
        result = described_class.call(
          visual_components_params: invalid_visual_components_params,
          data_app:,
          workspace:
        )

        expect(result).to be_a_failure
        expect(result.message).to include("Configurable must exist")
        expect(data_app.visual_components.count).to eq(0)
      end
    end

    context "when some visual components fail to be created with workflow configurable" do
      it "fails and sets the error message in the context" do
        result = described_class.call(
          visual_components_params: invalid_workflow_visual_components_params,
          data_app:,
          workspace:
        )

        expect(result).to be_a_failure
        expect(result.message).to include("Configurable must exist")
        expect(data_app.visual_components.count).to eq(0)
      end
    end
  end
end
