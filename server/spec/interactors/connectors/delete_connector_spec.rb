# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connectors::DeleteConnector do
  let(:workspace) { create(:workspace) }
  let(:connector) { create(:connector, workspace:) }

  describe "#call" do
    context "when connector has no dependencies" do
      it "successfully deletes the connector" do
        result = described_class.call(connector:)
        expect(result.success?).to eq(true)
        expect(Connector.exists?(connector.id)).to be false
      end
    end

    context "when connector is linked to models" do
      let!(:model) { create(:model, connector:, workspace:) }

      it "fails to delete the connector" do
        result = described_class.call(connector:)
        expect(result.failure?).to eq(true)
        expect(result.error).to include("Cannot delete connector")
        expect(result.error).to include("models")
        expect(Connector.exists?(connector.id)).to be true
      end

      it "does not delete the model" do
        described_class.call(connector:)
        expect(Model.exists?(model.id)).to be true
      end
    end

    context "when connector is used in workflow components" do
      let(:workflow) { create(:workflow, workspace:) }

      context "with llm_model component type" do
        let!(:component) do
          create(:component, workspace:, workflow:, component_type: :llm_model,
                             configuration: { "llm_model" => connector.id })
        end

        it "fails to delete the connector" do
          result = described_class.call(connector:)
          expect(result.failure?).to eq(true)
          expect(result.error).to include("Cannot delete connector")
          expect(result.error).to include("workflow components")
          expect(Connector.exists?(connector.id)).to be true
        end
      end

      context "with data_storage component type" do
        let!(:component) do
          create(:component, workspace:, workflow:, component_type: :data_storage,
                             configuration: { "database" => connector.id })
        end

        it "fails to delete the connector" do
          result = described_class.call(connector:)
          expect(result.failure?).to eq(true)
          expect(result.error).to include("workflow components")
        end
      end

      context "with vector_store component type" do
        let!(:component) do
          create(:component, workspace:, workflow:, component_type: :vector_store,
                             configuration: { "database" => connector.id })
        end

        it "fails to delete the connector" do
          result = described_class.call(connector:)
          expect(result.failure?).to eq(true)
          expect(result.error).to include("workflow components")
        end
      end

      context "with agent component type" do
        let!(:component) do
          create(:component, workspace:, workflow:, component_type: :agent,
                             configuration: { "llm_connector_id" => connector.id })
        end

        it "fails to delete the connector" do
          result = described_class.call(connector:)
          expect(result.failure?).to eq(true)
          expect(result.error).to include("workflow components")
        end
      end

      context "with llm_router component type" do
        let!(:component) do
          create(:component, workspace:, workflow:, component_type: :llm_router,
                             configuration: { "judge_llm_connector_id" => connector.id })
        end

        it "fails to delete the connector" do
          result = described_class.call(connector:)
          expect(result.failure?).to eq(true)
          expect(result.error).to include("workflow components")
        end
      end
    end

    context "when connector has multiple dependencies" do
      let(:workflow) { create(:workflow, workspace:) }
      let!(:model) { create(:model, connector:, workspace:) }
      let!(:component) do
        create(:component, workspace:, workflow:, component_type: :llm_model,
                           configuration: { "llm_model" => connector.id })
      end

      it "fails to delete and lists all dependencies" do
        result = described_class.call(connector:)
        expect(result.failure?).to eq(true)
        expect(result.error).to include("Cannot delete connector")
        expect(result.error).to include("models")
        expect(result.error).to include("workflow components")
      end

      it "does not delete the connector" do
        described_class.call(connector:)
        expect(Connector.exists?(connector.id)).to be true
      end

      it "does not delete associated resources" do
        described_class.call(connector:)
        expect(Model.exists?(model.id)).to be true
      end
    end

    context "when component references a different connector" do
      let(:workflow) { create(:workflow, workspace:) }
      let(:other_connector) { create(:connector, workspace:) }
      let!(:component) do
        create(:component, workspace:, workflow:, component_type: :llm_model,
                           configuration: { "llm_model" => other_connector.id })
      end

      it "successfully deletes the connector" do
        result = described_class.call(connector:)
        expect(result.success?).to eq(true)
        expect(Connector.exists?(connector.id)).to be false
      end

      it "does not affect the other connector" do
        described_class.call(connector:)
        expect(Connector.exists?(other_connector.id)).to be true
      end
    end

    context "when connector belongs to different workspace" do
      let(:other_workspace) { create(:workspace) }
      let(:other_workflow) { create(:workflow, workspace: other_workspace) }
      let!(:other_component) do
        create(:component, workspace: other_workspace, workflow: other_workflow,
                           component_type: :llm_model,
                           configuration: { "llm_model" => 999 })
      end

      it "successfully deletes the connector" do
        result = described_class.call(connector:)
        expect(result.success?).to eq(true)
        expect(Connector.exists?(connector.id)).to be false
      end
    end
  end
end
