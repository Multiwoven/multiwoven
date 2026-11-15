# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataApps::FetchVisualComponentData, type: :interactor do
  describe ".call" do
    let(:workspace) { create(:workspace) }
    let(:user) { workspace.workspace_users.first.user }
    let!(:data_app) { create(:data_app, workspace:, visual_components_count: 1) }
    let!(:ai_ml_connector) do
      create(:connector, connector_name: "DatabricksModel", workspace:,
                         connector_type: "source", connector_category: "AI Model")
    end
    let!(:ai_ml_model) do
      create(:model, query_type: :ai_ml, connector: ai_ml_connector, configuration: { harvesters: [] }, workspace:)
    end
    let!(:catalog) do
      create(
        :catalog,
        connector: ai_ml_connector,
        workspace:,
        catalog: {
          "streams" => [
            {
              "url" => "unknown",
              "name" => "DatabricksModel",
              "batch_size" => 0,
              "json_schema" => {
                "input" => [
                  { "name" => "messages.0.role", "type" => "string", "value" => "key1", "value_type" => "dynamic" },
                  { "name" => "messages.0.test", "type" => "string", "value" => "hai", "value_type" => "static" }
                ],
                "output" => [
                  { "name" => "response", "type": "string" }
                ]
              },
              "batch_support" => false,
              "request_method" => "POST"
            }
          ],
          "request_rate_limit" => 600,
          "request_rate_limit_unit" => "minute",
          "request_rate_concurrency" => 10
        },
        catalog_hash: "3688ef805acee1912a6f54e4c622c17ef11f5fc5"
      )
    end

    let!(:visual_component) { create(:visual_component, data_app:, workspace:, configurable: ai_ml_model) }

    let(:valid_fetch_params) do
      {
        visual_component_id: visual_component.id,
        harvest_values: {
          "key1" => "value1"
        }
      }
    end

    let(:invalid_fetch_params) do
      {
        visual_component_id: -1,
        harvest_values: {}
      }
    end

    let!(:session) { create(:data_app_session, data_app:, session_id: "sample_session_id") }
    let(:chat_message_user) do
      create(:chat_message, session:, role: "user",
                            content: "User message", workspace:, visual_component:)
    end
    let(:chat_message_assistant) do
      create(:chat_message, session:, role: "assistant", content: "Assistant message",
                            workspace:, visual_component:)
    end

    context "when the visual component is found and data is fetched successfully for chat bot" do
      let(:record) do
        Multiwoven::Integrations::Protocol::RecordMessage.new(
          data: {
            "id" => 1, "email" => "test1@mail.com", "first_name" => "John", "Last Name" => "Doe"
          },
          emitted_at: DateTime.now.to_i
        ).to_multiwoven_message
      end

      before do
        allow_any_instance_of(visual_component.model.connector.connector_client)
          .to receive(:read).and_return([record])
      end

      it "returns the fetched data" do
        result = described_class.call(
          data_app:,
          param: valid_fetch_params
        )

        expect(result).to be_a_success
        expect(result.result[:data]).to include(
          "id" => 1,
          "email" => "test1@mail.com",
          "first_name" => "John",
          "Last Name" => "Doe"
        )
        expect(result.result[:errors]).to be_nil
      end
    end

    context "when the visual component is found and data is fetched successfully" do
      let(:record) do
        Multiwoven::Integrations::Protocol::RecordMessage.new(
          data: {
            "model" => "llama3.2", "created_at" => "2024-12-13T12:49:16.349172Z", "response" => "hello"
          },
          emitted_at: DateTime.now.to_i
        ).to_multiwoven_message
      end
      let(:payload) do
        "{\"messages\":[{\"role\":\"This is an ongoing conversation between a user and an AI assistant. "\
        "The assistant should provide helpful, relevant responses directly to the user's query in a "\
        "natural and conversational manner.\\n\\n" \
        "Conversation History:\\n"\
        "User: User message\\n" \
        "Assistant: Assistant message\\n\\n" \
        "User's Query:\\nvalue1\\n\\n\\n"\
        "Please respond directly to the user's query.\",\"test\":\"hai\"}]}"
      end

      let(:sync_config) { subject.build_sync_config(visual_component.model, payload) }

      before do
        chat_message_user
        chat_message_assistant
        visual_component.update(component_type: "chat_bot")
        allow_any_instance_of(visual_component.model.connector.connector_client)
          .to receive(:read).with(sync_config).and_return([record])
      end

      it "returns the fetched data" do
        result = described_class.call(
          data_app:,
          session:,
          param: valid_fetch_params
        )

        expect(result).to be_a_success
        expect(result.result[:data]).to include(
          "created_at" => "2024-12-13T12:49:16.349172Z",
          "model" => "llama3.2",
          "response" => "hello"
        )
        expect(result.result[:errors]).to be_nil
        expect(session.chat_messages.count).to eq(4)
        expect(session.chat_messages.last.content).to eq("hello")
        expect(session.chat_messages[-2].content).to eq("value1")
      end
    end

    context "when no data is returned" do
      before do
        allow_any_instance_of(visual_component.model.connector.connector_client)
          .to receive(:read).and_return(nil) # Simulate no data found
      end

      it "returns an error message" do
        result = described_class.call(
          data_app:,
          param: valid_fetch_params
        )

        expect(result).to be_a_success
        expect(result.result[:errors]).to eq("No data found")
      end
    end

    context "when visual component is not found" do
      it "raises an error and returns a failure" do
        result = described_class.call(
          data_app:,
          param: invalid_fetch_params
        )
        expect(result.result[:errors]).to eq("Visual Component not found")
      end
    end

    context "when an exception is raised during the fetch process" do
      before do
        allow_any_instance_of(DataApps::FetchVisualComponentData)
          .to receive(:build_payload).and_raise(StandardError, "Some error occurred")
      end

      it "captures the exception and returns an error message" do
        result = described_class.call(
          data_app:,
          param: valid_fetch_params
        )

        expect(result.result[:errors]).to eq("Some error occurred")
      end
    end
  end
end
