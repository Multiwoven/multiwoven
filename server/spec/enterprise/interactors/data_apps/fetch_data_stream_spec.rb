# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataApps::FetchDataStream, type: :service do
  describe "#call" do
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
    let!(:session) { create(:data_app_session, data_app:, session_id: "sample_session_id") }
    let(:chat_message_user) do
      create(:chat_message, session:, role: "user",
                            content: "User message", workspace:, visual_component:)
    end
    let(:chat_message_assistant) do
      create(:chat_message, session:, role: "assistant", content: "Assistant message",
                            workspace:, visual_component:)
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

    let!(:visual_component) do
      create(:visual_component, data_app:, workspace:, configurable: ai_ml_model, component_type: "chat_bot")
    end

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

    let(:mismatched_fetch_params) do
      {
        visual_component_id: visual_component.id,
        harvest_values: {
          "abc" => "value1"
        }
      }
    end

    context "when the visual component is found and data is fetched successfully" do
      let(:record) do
        Multiwoven::Integrations::Protocol::RecordMessage.new(
          data: {
            "model": "llama3.2", "created_at": "2024-12-13T12:49:16.349172Z", "response": "hello", "done": false
          },
          emitted_at: DateTime.now.to_i
        ).to_multiwoven_message
      end
      let(:record1) do
        Multiwoven::Integrations::Protocol::RecordMessage.new(
          data: {
            "model": "llama3.2", "created_at": "2024-12-13T12:49:16.349172Z", "response": "world", "done": false
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
        allow_any_instance_of(visual_component.model.connector.connector_client).to receive(:read)
          .with(sync_config) do |&block|
            block.call([record])
            block.call([record1])
          end
      end

      it "yields the fetched data" do
        yielded_data = []
        described_class.new.call(data_app, session, valid_fetch_params) do |record|
          yielded_data << record
        end
        expect(yielded_data.size).to eq(2)
        expect(yielded_data[0][:response]).to eq("hello")
        expect(yielded_data[1][:response]).to eq("world")
        expect(session.chat_messages.count).to eq(4)
        expect(session.chat_messages.last.content).to eq("helloworld")
        expect(session.chat_messages[-2].content).to eq("value1")
      end
    end

    context "when the visual component is found and data is fetched but harvest data does not match input schema" do
      it "yields error" do
        expect do
          described_class.new.call(data_app, session, mismatched_fetch_params)
        end.to raise_error(
          StandardError,
          "Validation failed: Harvested values does not match any expected input schema values " \
          "for visual_component_id: #{visual_component.id}"
        )
      end
    end

    context "when visual component is not found" do
      it "raises an error and does not yield any data" do
        expect do
          described_class.new.call(data_app, session, invalid_fetch_params)
        end.to raise_error(StandardError, "Visual Component not found for visual_component_id: -1")
      end
    end

    context "when visual component is found" do
      before do
        visual_component.update(component_type: "bar")
      end
      it "raises an error for un supported component type" do
        expect do
          described_class.new.call(data_app, session, valid_fetch_params)
        end.to raise_error(
          StandardError,
          "Visual Component is not stream-based for visual_component_id: #{valid_fetch_params[:visual_component_id]}"
        )
      end
    end

    context "when an exception is raised during the fetch process" do
      before do
        allow_any_instance_of(DataApps::FetchDataStream)
          .to receive(:build_payload).and_raise(StandardError, "Some error occurred")
      end

      it "captures the exception and raises an error message" do
        expect do
          described_class.new.call(data_app, session, valid_fetch_params)
        end.to raise_error(
          StandardError, "Some error occurred for visual_component_id: #{valid_fetch_params[:visual_component_id]}"
        )
      end
    end

    context "when an exception is raised during the fetch process" do
      let(:invalid_message) do
        Multiwoven::Integrations::Protocol::LogMessage.new(
          level: "error",
          message: "Error: Incorrect API key provided",
          name: "OPEN AI:RUN_STREAM_MODEL:EXCEPTION"
        ).to_multiwoven_message
      end

      before do
        allow_any_instance_of(visual_component.model.connector.connector_client).to receive(:read)
          .and_return(invalid_message)
      end

      it "captures the exception and raises an error message" do
        expect do
          described_class.new.call(data_app, session, valid_fetch_params)
        end.to raise_error(
          StandardError,
          "Error: Incorrect API key provided for visual_component_id: #{valid_fetch_params[:visual_component_id]}"
        )
      end
    end
  end
end
