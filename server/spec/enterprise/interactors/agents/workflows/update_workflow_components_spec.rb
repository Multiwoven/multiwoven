# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::Workflows::UpdateWorkflowComponents do
  describe ".call" do
    let(:workflow) { create(:workflow) }
    let(:existing_component) { create(:component, workflow:, name: "Old Component") }
    let(:components_params) do
      [
        {
          id: existing_component.id,
          name: "Updated Component",
          component_type: "chat_input",
          component_category: "generic_component",
          configuration: { "key" => "value" },
          data: { "category" => "input_output",
                  "component" => "chat_input",
                  "label" => "Chat Input" },
          position: { "x" => 100, "y" => 200 }
        },
        {
          id: "new-component-1",
          name: "New Component",
          component_type: "chat_output",
          component_category: "generic_component",
          configuration: { "key" => "value" },
          data: { "category" => "input_output",
                  "component" => "chat_input",
                  "label" => "Chat Input" },
          position: { "x" => 300, "y" => 400 }
        }
      ]
    end

    let(:context) { { workflow:, components_params: } }
    let(:knowledge_base) { create(:knowledge_base) }
    let(:new_knowledge_base) { create(:knowledge_base) }
    let(:knowledge_base_file) { create(:knowledge_base_file, knowledge_base:) }
    let(:new_knowledge_base_file) { create(:knowledge_base_file, knowledge_base: new_knowledge_base) }
    let(:knowledge_base_context) do
      {
        workflow:,
        components_params: [
          {
            id: existing_component.id,
            component_type: "knowledge_base",
            component_category: "generic_component",
            data: { "category" => "input_output",
                    "component" => "chat_input",
                    "label" => "Chat Input" },
            position: { "x" => 100, "y" => 200 },
            configuration: {
              "knowledge_base" => knowledge_base.id
            }
          }
        ]
      }
    end

    before do
      existing_component # Create the existing component
    end

    it "updates existing components and creates new ones" do
      result = described_class.call(context)

      expect(result).to be_success

      # Check updated component
      updated_component = workflow.components.find(existing_component.id)
      expect(updated_component.name).to eq("Updated Component")
      expect(updated_component.component_type).to eq("chat_input")
      expect(updated_component.configuration).to eq({ "key" => "value" })
      expect(updated_component.position).to eq({ "x" => 100, "y" => 200 })

      # Check new component
      new_component = workflow.components.find_by(id: "new-component-1")
      expect(new_component).to be_present
      expect(new_component.name).to eq("New Component")
      expect(new_component.component_type).to eq("chat_output")
      expect(new_component.configuration).to eq({ "key" => "value" })
      expect(new_component.position).to eq({ "x" => 300, "y" => 400 })
    end

    context "when components_params is blank" do
      let(:components_params) { [] }

      it "removes all existing components" do
        expect { described_class.call(context) }.to change { workflow.components.count }.to(0)
      end
    end

    context "when component update fails" do
      let(:components_params) do
        [
          {
            id: existing_component.id,
            name: "", # Invalid empty name
            component_type: "chat_input",
            configuration: { "key" => "value" }
          }
        ]
      end

      it "raises an error" do
        expect { described_class.call(context) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when component ID already exists in another workflow" do
      let(:other_workflow) { create(:workflow) }
      let!(:other_component) { create(:component, workflow: other_workflow, id: "shared-component-id") }

      let(:components_params) do
        [
          {
            id: "shared-component-id", # Same ID as component in other workflow
            name: "New Component",
            component_type: "chat_input",
            component_category: "generic_component",
            configuration: { "key" => "value" },
            data: { "category" => "input_output",
                    "component" => "chat_input",
                    "label" => "Chat Input" },
            position: { "x" => 100, "y" => 200 }
          }
        ]
      end

      it "raises StandardError with appropriate error message" do
        expect do
          described_class.call(context)
        end.to raise_error(StandardError,
                           "Component with ID 'shared-component-id' already exists in another workflow")
      end
    end

    context "when component ID already exists in the same workflow" do
      let(:components_params) do
        [
          {
            id: existing_component.id, # Same ID as existing component in same workflow
            name: "Updated Component",
            component_type: "chat_input",
            component_category: "generic_component",
            configuration: { "key" => "value" },
            data: { "category" => "input_output",
                    "component" => "chat_input",
                    "label" => "Chat Input" },
            position: { "x" => 100, "y" => 200 }
          }
        ]
      end

      it "allows updating the existing component" do
        result = described_class.call(context)

        expect(result).to be_success
        updated_component = workflow.components.find(existing_component.id)
        expect(updated_component.name).to eq("Updated Component")
      end
    end

    context "when a knowledge base component is updated" do
      before do
        knowledge_base.knowledge_base_files << knowledge_base_file
        new_knowledge_base.knowledge_base_files << new_knowledge_base_file
        knowledge_base.save!
        new_knowledge_base.save!
      end

      it "enables the knowledge base file for the workflow" do
        result = described_class.call(knowledge_base_context)
        expect(result).to be_success
        expect(knowledge_base.reload.knowledge_base_files.first.workflow_enabled).to be_truthy
        expect(new_knowledge_base.reload.knowledge_base_files.first.workflow_enabled).to be_falsey
      end

      it "disables the knowledge base file for the workflow" do
        result = described_class.call(knowledge_base_context)
        expect(result).to be_success
        expect(knowledge_base.reload.knowledge_base_files.first.workflow_enabled).to be_truthy
        expect(new_knowledge_base.reload.knowledge_base_files.first.workflow_enabled).to be_falsey

        knowledge_base_context[:components_params][0][:configuration]["knowledge_base"] = new_knowledge_base.id
        result = described_class.call(knowledge_base_context)
        expect(result).to be_success
        expect(knowledge_base.reload.knowledge_base_files.first.workflow_enabled).to be_falsey
        expect(new_knowledge_base.reload.knowledge_base_files.first.workflow_enabled).to be_truthy
      end
    end

    context "when a knowledge base component is deleted" do
      before do
        knowledge_base.knowledge_base_files << knowledge_base_file
        knowledge_base.save!
      end

      it "disables the knowledge base file for the workflow" do
        described_class.call(knowledge_base_context)
        expect(knowledge_base.reload.knowledge_base_files.first.workflow_enabled).to be_truthy
        knowledge_base_context[:components_params] = []
        result = described_class.call(knowledge_base_context)
        expect(result).to be_success
        expect(knowledge_base.reload.knowledge_base_files.first.workflow_enabled).to be_falsey
      end
    end

    context "when a component configuration contains a masked value" do
      let(:masked) { Utils::SecretMasking::MASKED_VALUE }
      let(:original_api_key) { "real-secret-key" }

      before do
        existing_component.update!(configuration: { "api_key" => original_api_key, "limit" => 5 })
      end

      let(:components_params) do
        [
          {
            id: existing_component.id,
            name: "Updated Component",
            component_type: "chat_input",
            component_category: "generic_component",
            configuration: { "api_key" => masked, "limit" => 10 },
            data: { "category" => "input_output", "component" => "chat_input", "label" => "Chat Input" },
            position: { "x" => 0, "y" => 0 }
          }
        ]
      end

      it "updates non-masked fields and preserves the masked key's existing value" do
        result = described_class.call(context)

        expect(result).to be_success
        updated = workflow.components.find(existing_component.id)
        expect(updated.name).to eq("Updated Component")
        expect(updated.configuration["api_key"]).to eq(original_api_key)
        expect(updated.configuration["limit"]).to eq(10)
      end
    end

    context "when some components have masked values and others do not" do
      let(:masked) { Utils::SecretMasking::MASKED_VALUE }
      let(:original_api_key) { "original-secret" }

      before do
        existing_component.update!(configuration: { "api_key" => original_api_key })
      end

      let(:components_params) do
        [
          {
            id: existing_component.id,
            name: "Updated Component",
            component_type: "chat_input",
            component_category: "generic_component",
            configuration: { "api_key" => masked },
            data: { "category" => "input_output", "component" => "chat_input", "label" => "Chat Input" },
            position: { "x" => 0, "y" => 0 }
          },
          {
            id: "new-clean-component",
            name: "Clean Component",
            component_type: "chat_output",
            component_category: "generic_component",
            configuration: { "key" => "real_value" },
            data: { "category" => "input_output", "component" => "chat_output", "label" => "Chat Output" },
            position: { "x" => 100, "y" => 0 }
          }
        ]
      end

      it "updates the masked component preserving secret, and creates the clean component" do
        result = described_class.call(context)

        expect(result).to be_success
        updated = workflow.components.find(existing_component.id)
        expect(updated.name).to eq("Updated Component")
        expect(updated.configuration["api_key"]).to eq(original_api_key)
        expect(workflow.components.find_by(id: "new-clean-component")).to be_present
      end
    end

    context "when a file_input component is removed" do
      let!(:file_input_component) { create(:component, workflow:, component_type: :file_input) }
      let!(:workflow_file) { create(:workflow_file, workflow:) }

      let(:components_params) do
        [
          {
            id: existing_component.id,
            name: "Updated Component",
            component_type: "chat_input",
            component_category: "generic_component",
            configuration: {},
            data: { "category" => "input_output", "component" => "chat_input" }
          }
        ]
      end

      it "destroys all workflow files for the workflow" do
        expect { described_class.call(context) }.to change { Agents::WorkflowFile.count }.by(-1)
        expect(Agents::WorkflowFile.exists?(workflow_file.id)).to be false
      end

      it "deletes the file_input component" do
        described_class.call(context)
        expect(Agents::Component.exists?(file_input_component.id)).to be false
      end
    end
  end
end
