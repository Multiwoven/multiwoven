# frozen_string_literal: true

require "rails_helper"

RSpec.describe Workflow::Components::LlmModelComponent do
  let(:workspace) { create(:workspace) }
  let(:workflow) { create(:workflow, workspace:) }
  let(:workflow_run) { create(:workflow_run, workflow:, workspace:) }
  let(:component) { described_class.new(config:, workflow_run:) }
  let(:connector) { create(:connector, workspace:, connector_name: "openai", connector_type: :source) }
  let(:mock_response) { double("response") }

  before do
    component.inputs = input_data
  end

  let(:input_data) { { "user_prompt" => "Hello, how are you?" } }
  let(:config) do
    {
      "llm_model" => connector.id,
      "instructions" => "You are a helpful assistant."
    }
  end

  describe "#run" do
    context "when input validation passes" do
      before do
        # Mock the connector lookup through the workspace
        allow(workspace.connectors).to receive(:find).with(connector.id).and_return(connector)
        allow(connector).to receive(:configuration).and_return(connector_config)
        allow(connector).to receive(:generate_response).and_return(mock_response)
        allow(component).to receive(:extract_assistant_response).and_return("I'm doing well, thank you!")
        # No persisted @component in this context; stub to avoid log_direct_usage calling @component.id
        allow(component).to receive(:log_llm_usage)
      end

      let(:connector_config) do
        {
          "request_format" => {
            "model" => "gpt-3.5-turbo",
            "messages" => [
              { "role" => "user", "content" => "Hello" }
            ]
          }.to_json
        }
      end

      it "executes successfully and returns model results" do
        component.run

        expect(component.instance_variable_get(:@output_data)).to eq(
          {
            "model_results" => "I'm doing well, thank you!"
          }
        )
      end

      it "calls build_llm_payload with correct parameters" do
        expect(component).to receive(:build_llm_payload).and_call_original
        component.run
      end

      it "calls generate_response with the built payload" do
        expected_payload = {
          "model" => "gpt-3.5-turbo",
          "messages" => [
            { "role" => "system", "content" => "You are a helpful assistant." },
            { "role" => "user", "content" => "Hello, how are you?" }
          ]
        }

        expect(connector).to receive(:generate_response).with(expected_payload.to_json)
        component.run
      end

      it "calls extract_assistant_response with the raw response and connector" do
        expect(component).to receive(:extract_assistant_response).with(mock_response, connector).and_call_original
        component.run
      end
    end

    context "when user_prompt is missing" do
      let(:input_data) { { "user_prompt" => "" } }

      it "raises an error" do
        expect { component.run }.to raise_error(StandardError) do |error|
          expect(error.message).to eq("Missing input 'user_prompt'")
        end
      end
    end

    context "when user_prompt is nil" do
      let(:input_data) { { "user_prompt" => nil } }

      it "raises an error" do
        expect { component.run }.to raise_error(StandardError) do |error|
          expect(error.message).to eq("Missing input 'user_prompt'")
        end
      end
    end

    context "LLM usage logging" do
      let(:llm_component_db) do
        create(:component, workflow:, workspace:, component_type: :llm_model, configuration: config)
      end
      let(:component_with_db) { described_class.new(config:, workflow_run:, component: llm_component_db) }
      let(:response_text) { "I'm doing well, thank you!" }

      before do
        component_with_db.inputs = input_data
        allow(workflow_run.workspace.connectors).to receive(:find).with(connector.id).and_return(connector)
        allow(connector).to receive(:configuration).and_return(connector_config)
        allow(connector).to receive(:generate_response).and_return(mock_response)
        allow(component_with_db).to receive(:extract_assistant_response).and_return(response_text)
        allow_any_instance_of(LlmUsage::TokenEstimator).to receive(:estimate_tokens) do |_receiver, text|
          text == input_data["user_prompt"] ? 100 : 200
        end
        allow(Utils::HttpClient).to receive(:get).and_return(
          { "data" => [{ "id" => "openai/gpt-3.5-turbo", "pricing" => { "prompt" => 0.001, "completion" => 0.002 } }] }
        )
      end

      let(:connector_config) do
        {
          "request_format" => {
            "model" => "gpt-3.5-turbo",
            "messages" => []
          }.to_json
        }
      end

      it "creates an LlmUsageLog when run completes successfully" do
        expect { component_with_db.run }.to change(LlmUsageLog, :count).by(1)

        log = LlmUsageLog.last
        expect(log.workspace_id).to eq(workspace.id)
        expect(log.workflow_run_id).to eq(workflow_run.id)
        expect(log.component_id).to eq(llm_component_db.id.to_s)
        expect(log.connector_id).to eq(connector.id.to_s)
        expect(log.prompt_hash).to eq(Digest::SHA256.hexdigest(input_data["user_prompt"]))
        expect(log.selected_model).to eq("gpt-3.5-turbo")
        expect(log.estimated_input_tokens).to eq(100)
        expect(log.estimated_output_tokens).to eq(200)
        expect(log.total_cost).to eq(0.5)
        expect(log.provider).to eq(connector.connector_name)
      end

      it "does not create an LlmUsageLog when run raises an error" do
        allow(connector).to receive(:generate_response).and_raise(StandardError.new("API request failed"))

        expect { component_with_db.run }.to raise_error(StandardError, "API request failed")
        expect(LlmUsageLog.where(workflow_run_id: workflow_run.id)).to be_empty
      end
    end
  end

  describe "provider-specific payload generation" do
    before do
      allow(workspace.connectors).to receive(:find).with(connector.id).and_return(connector)
    end

    context "with OpenAI connector" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_name: "OpenAI",
               connector_type: :source,
               configuration: {
                 "request_format" => {
                   "model" => "gpt-4o-mini",
                   "temperature" => 0.7
                 }.to_json
               })
      end

      it "generates OpenAI-formatted payload" do
        messages = component.send(:build_messages_with_history)
        result = component.send(:build_llm_payload, connector, messages, "You are a helpful assistant.")

        expect(result["model"]).to eq("gpt-4o-mini")
        expect(result["messages"].first["role"]).to eq("system")
        expect(result["messages"].first["content"]).to eq("You are a helpful assistant.")
        expect(result["temperature"]).to eq(0.7)
      end
    end

    context "with Anthropic connector" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_name: "Anthropic",
               connector_type: :source,
               configuration: {
                 "request_format" => {
                   "model" => "claude-opus-4-5-20251101",
                   "max_tokens" => 4096
                 }.to_json
               })
      end

      it "generates Anthropic-formatted payload with top-level system parameter" do
        messages = component.send(:build_messages_with_history)
        result = component.send(:build_llm_payload, connector, messages, "You are a helpful assistant.")

        expect(result["model"]).to eq("claude-opus-4-5-20251101")
        expect(result["system"]).to eq("You are a helpful assistant.")
        expect(result["max_tokens"]).to eq(4096)
        expect(result["messages"].none? { |m| m["role"] == "system" }).to be true
        expect(result["messages"].first["role"]).to eq("user")
      end

      it "combines system messages from chat history with instructions" do
        # Set up workflow_run with session_id to trigger chat history fetching
        workflow_run.inputs["session_id"] = "test-session-id"
        # Mock chat history with system message
        chat_history = [
          { "role" => "system", "content" => "Previous system context" },
          { "role" => "user", "content" => "Previous question" },
          { "role" => "assistant", "content" => "Previous answer" }
        ]
        allow(component).to receive(:fetch_chat_history).and_return(chat_history)

        messages = component.send(:build_messages_with_history)
        result = component.send(:build_llm_payload, connector, messages, "You are a helpful assistant.")

        expect(result["system"]).to include("Previous system context")
        expect(result["system"]).to include("You are a helpful assistant.")
        expect(result["messages"].none? { |m| m["role"] == "system" }).to be true
      end
    end

    context "with AWS Bedrock connector (Anthropic model)" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_name: "AwsBedrockModel",
               connector_type: :source,
               configuration: {
                 "request_format" => {
                   "model" => "anthropic.claude-sonnet-4-20250514-v1:0",
                   "max_tokens" => 2048
                 }.to_json
               })
      end

      it "uses Anthropic format for Anthropic models on Bedrock" do
        messages = component.send(:build_messages_with_history)
        result = component.send(:build_llm_payload, connector, messages, "You are a helpful assistant.")

        expect(result["model"]).to eq("anthropic.claude-sonnet-4-20250514-v1:0")
        expect(result["system"]).to eq("You are a helpful assistant.")
        expect(result["max_tokens"]).to eq(2048)
        expect(result["messages"].none? { |m| m["role"] == "system" }).to be true
      end
    end

    context "with AWS Bedrock connector (Titan model)" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_name: "AwsBedrockModel",
               connector_type: :source,
               configuration: {
                 "request_format" => {
                   "model" => "amazon.titan-text-express-v1",
                   "max_tokens" => 1024
                 }.to_json
               })
      end

      it "uses standard format for non-Anthropic models on Bedrock" do
        messages = component.send(:build_messages_with_history)
        result = component.send(:build_llm_payload, connector, messages, "You are a helpful assistant.")

        expect(result["model"]).to eq("amazon.titan-text-express-v1")
        expect(result["messages"].first["role"]).to eq("system")
        expect(result["max_tokens"]).to eq(1024)
      end
    end

    context "with GenericOpenAI connector" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_name: "GenericOpenAI",
               connector_type: :source,
               configuration: {
                 "request_format" => {
                   "model" => "custom-llm-v1"
                 }.to_json
               })
      end

      it "uses OpenAI format" do
        messages = component.send(:build_messages_with_history)
        result = component.send(:build_llm_payload, connector, messages, "You are a helpful assistant.")

        expect(result["model"]).to eq("custom-llm-v1")
        expect(result["messages"].first["role"]).to eq("system")
      end
    end
  end

  describe "#extract_assistant_response" do
    let(:openai_connector) do
      create(:connector, workspace:, connector_name: "OpenAI", connector_type: :source)
    end

    let(:anthropic_connector) do
      create(:connector, workspace:, connector_name: "Anthropic", connector_type: :source)
    end

    context "when response is valid" do
      let(:mock_record) { double("record", data: response_data, present?: true) }
      let(:mock_response) { [double("response_item", record: mock_record, log: nil)] }
      let(:response_data) do
        {
          "choices" => [
            {
              "message" => {
                "content" => "I'm doing well, thank you!"
              }
            }
          ]
        }
      end

      it "extracts the assistant response content from OpenAI" do
        result = component.send(:extract_assistant_response, mock_response, openai_connector)
        expect(result).to eq("I'm doing well, thank you!")
      end

      it "extracts the assistant response content from Anthropic" do
        anthropic_response_data = {
          "model" => "claude-opus-4-5-20251101",
          "id" => "msg_01FLuL7snaTEDqvcYKn8joBB",
          "type" => "message",
          "role" => "assistant",
          "content" => [
            {
              "type" => "text",
              "text" => "I'm doing well, thank you!"
            }
          ],
          "stop_reason" => "end_turn"
        }
        anthropic_mock_record = double("record", data: anthropic_response_data, present?: true)
        anthropic_mock_response = [double("response_item", record: anthropic_mock_record, log: nil)]
        result = component.send(:extract_assistant_response, anthropic_mock_response, anthropic_connector)
        expect(result).to eq("I'm doing well, thank you!")
      end
    end

    context "when response is nil" do
      it "raises an error" do
        expect { component.send(:extract_assistant_response, nil, openai_connector) }
          .to raise_error("LLM API request failed: Invalid response - response is nil")
      end
    end

    context "when response is not an array" do
      let(:mock_message) { double("message", log: nil, record: nil) }

      it "returns nil" do
        result = component.send(:extract_assistant_response, mock_message, openai_connector)
        expect(result).to be_nil
      end
    end

    context "when response array is empty" do
      it "returns nil" do
        result = component.send(:extract_assistant_response, [], openai_connector)
        expect(result).to be_nil
      end
    end

    context "when first item doesn't respond to record" do
      let(:mock_response) { [double("response_item", log: nil)] }

      it "returns nil" do
        result = component.send(:extract_assistant_response, mock_response, openai_connector)
        expect(result).to be_nil
      end
    end

    context "when response data doesn't have expected structure" do
      let(:mock_record) { double("record", data: {}, present?: true) }
      let(:mock_response) { [double("response_item", record: mock_record, log: nil)] }

      it "returns nil" do
        result = component.send(:extract_assistant_response, mock_response, openai_connector)
        expect(result).to be_nil
      end
    end

    context "when response contains error LogMessage" do
      let(:log_message) do
        Multiwoven::Integrations::Protocol::LogMessage.new(
          message: "API request failed: Invalid API key",
          level: "error"
        )
      end
      let(:mock_response) { [double("response_item", log: log_message)] }

      it "raises an error with the log message" do
        expect { component.send(:extract_assistant_response, mock_response, openai_connector) }
          .to raise_error("LLM API request failed: API request failed: Invalid API key")
      end
    end
  end

  describe "integration tests with different providers" do
    let(:mock_record) { double("record", data: response_data, present?: true) }
    let(:mock_response) { [double("response_item", record: mock_record, log: nil)] }
    let(:response_data) do
      {
        "choices" => [
          {
            "message" => {
              "content" => "Provider-specific response"
            }
          }
        ]
      }
    end

    before do
      allow(workspace.connectors).to receive(:find).with(connector.id).and_return(connector)
      allow(connector).to receive(:generate_response).and_return(mock_response)
      # No persisted @component in this describe; stub to avoid log_llm_usage calling @component.id
      allow(component).to receive(:log_llm_usage)
    end

    context "with Anthropic connector" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_name: "Anthropic",
               connector_type: :source,
               configuration: {
                 "request_format" => {
                   "model" => "claude-opus-4-5-20251101",
                   "max_tokens" => 4096
                 }.to_json
               })
      end

      let(:response_data) do
        {
          "model" => "claude-opus-4-5-20251101",
          "id" => "msg_01FLuL7snaTEDqvcYKn8joBB",
          "type" => "message",
          "role" => "assistant",
          "content" => [
            {
              "type" => "text",
              "text" => "Provider-specific response"
            }
          ],
          "stop_reason" => "end_turn"
        }
      end

      it "successfully executes with Anthropic-specific payload" do
        component.run

        expect(connector).to have_received(:generate_response) do |payload_json|
          payload = JSON.parse(payload_json)
          expect(payload["system"]).to eq("You are a helpful assistant.")
          expect(payload["max_tokens"]).to eq(4096)
          expect(payload["messages"].none? { |m| m["role"] == "system" }).to be true
        end

        expect(component.instance_variable_get(:@output_data)).to eq(
          {
            "model_results" => "Provider-specific response"
          }
        )
      end
    end

    context "with OpenAI connector" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_name: "OpenAI",
               connector_type: :source,
               configuration: {
                 "request_format" => {
                   "model" => "gpt-4o-mini",
                   "temperature" => 0.7
                 }.to_json
               })
      end

      it "successfully executes with OpenAI-specific payload" do
        component.run

        expect(connector).to have_received(:generate_response) do |payload_json|
          payload = JSON.parse(payload_json)
          expect(payload["messages"].first["role"]).to eq("system")
          expect(payload["messages"].first["content"]).to eq("You are a helpful assistant.")
          expect(payload["temperature"]).to eq(0.7)
        end

        expect(component.instance_variable_get(:@output_data)).to eq(
          {
            "model_results" => "Provider-specific response"
          }
        )
      end
    end
  end

  describe "chat history functionality" do
    let(:data_app) { create(:data_app, workspace:) }
    let(:data_app_session) { create(:data_app_session, data_app:, workspace:, session_id: "test-session-123") }
    let(:visual_component) { create(:visual_component, data_app:, workspace:) }
    let(:input_data) { { "user_prompt" => "What's the weather like?" } }
    let(:workflow_run) { create(:workflow_run, workflow:, workspace:, inputs: { "session_id" => "test-session-123" }) }

    before do
      # Create some chat history (session is polymorphic: use session: data_app_session)
      create(:chat_message,
             session: data_app_session,
             visual_component:,
             workspace:,
             role: "user",
             content: "Hello, how are you?")
      create(:chat_message,
             session: data_app_session,
             visual_component:,
             workspace:,
             role: "assistant",
             content: "I'm doing well, thank you!")
      create(:chat_message,
             session: data_app_session,
             visual_component:,
             workspace:,
             role: "user",
             content: "What's your name?")
      create(:chat_message,
             session: data_app_session,
             visual_component:,
             workspace:,
             role: "assistant",
             content: "I'm an AI assistant.")
    end

    describe "#fetch_chat_history" do
      it "returns chat history from the session" do
        result = component.send(:fetch_chat_history)

        expect(result).to be_an(Array)
        expect(result.length).to eq(4)
        expect(result[0]).to eq({ "role" => "user", "content" => "Hello, how are you?" })
        expect(result[1]).to eq({ "role" => "assistant", "content" => "I'm doing well, thank you!" })
        expect(result[2]).to eq({ "role" => "user", "content" => "What's your name?" })
        expect(result[3]).to eq({ "role" => "assistant", "content" => "I'm an AI assistant." })
      end

      it "returns empty array when session_id is not present" do
        workflow_run_without_session = create(:workflow_run, workflow:, workspace:, inputs: {})
        component_without_session = described_class.new(config:, workflow_run: workflow_run_without_session)
        component_without_session.inputs = { "user_prompt" => "Hello" }
        result = component_without_session.send(:fetch_chat_history)
        expect(result).to eq([])
      end

      it "returns empty array when session is not found" do
        workflow_run_with_invalid_session = create(:workflow_run, workflow:, workspace:,
                                                                  inputs: { "session_id" => "non-existent-session" })
        component_with_invalid_session = described_class.new(config:, workflow_run: workflow_run_with_invalid_session)
        component_with_invalid_session.inputs = { "user_prompt" => "Hello" }
        result = component_with_invalid_session.send(:fetch_chat_history)
        expect(result).to eq([])
      end
    end

    describe "#build_messages_with_history" do
      it "builds messages with chat history" do
        result = component.send(:build_messages_with_history)

        expect(result).to be_an(Array)
        expect(result.length).to eq(5) # 4 history + 1 current user

        # Check that history is included
        expect(result[0]).to eq({ "role" => "user", "content" => "Hello, how are you?" })
        expect(result[1]).to eq({ "role" => "assistant", "content" => "I'm doing well, thank you!" })
        expect(result[2]).to eq({ "role" => "user", "content" => "What's your name?" })
        expect(result[3]).to eq({ "role" => "assistant", "content" => "I'm an AI assistant." })

        # Check that current user prompt is added
        expect(result[4]).to eq({ "role" => "user", "content" => "What's the weather like?" })
      end

      it "builds messages without chat history when no session_id" do
        workflow_run_without_session = create(:workflow_run, workflow:, workspace:, inputs: {})
        component_without_session = described_class.new(config:, workflow_run: workflow_run_without_session)
        component_without_session.inputs = { "user_prompt" => "What's the weather like?" }

        result = component_without_session.send(:build_messages_with_history)

        # Should only include current user prompt
        expect(result).to eq([
                               { "role" => "user", "content" => "What's the weather like?" }
                             ])
      end
    end

    describe "payload generation with chat history" do
      let(:openai_connector) do
        create(:connector,
               workspace:,
               connector_name: "OpenAI",
               connector_type: :source,
               configuration: {
                 "request_format" => {
                   "model" => "gpt-3.5-turbo"
                 }.to_json
               })
      end

      before do
        allow(workspace.connectors).to receive(:find).with(openai_connector.id).and_return(openai_connector)
      end

      it "includes chat history in the payload" do
        messages = component.send(:build_messages_with_history)
        result = component.send(:build_llm_payload, openai_connector, messages, "You are a helpful assistant.")

        expect(result["messages"]).to be_an(Array)
        expect(result["messages"].length).to be > 1

        # Should include system message
        system_message = result["messages"].find { |m| m["role"] == "system" }
        expect(system_message).to be_present
        expect(system_message["content"]).to eq("You are a helpful assistant.")

        # Should include chat history
        expect(result["messages"].any? { |m| m["content"] == "Hello, how are you?" }).to be true
        expect(result["messages"].any? { |m| m["content"] == "I'm doing well, thank you!" }).to be true
        expect(result["messages"].any? { |m| m["content"] == "What's the weather like?" }).to be true
      end
    end
  end

  describe "#executable?" do
    let(:llm_component_db) { create(:component, workflow:, component_type: :llm_model, configuration: config) }
    let(:component_with_db) { described_class.new(config:, workflow_run:, component: llm_component_db) }

    context "when component is not connected to any router" do
      it "returns true (should be executed in normal DAG flow)" do
        expect(component_with_db.executable?).to be true
      end
    end

    context "when component is connected to an LLM router" do
      let(:router_component) do
        create(:component, workflow:, component_type: :llm_router,
                           configuration: { "judge_llm_connector_id" => connector.id })
      end

      before do
        # Create edge from LLM component to router
        create(:edge, workflow:, workspace:,
                      source_component: llm_component_db,
                      target_component: router_component)
        # Reload to pick up the new edge
        llm_component_db.reload
      end

      it "returns false (should be skipped in normal DAG flow)" do
        expect(component_with_db.executable?).to be false
      end
    end

    context "when component is connected to a non-router component" do
      let(:agent_component) do
        create(:component, workflow:, component_type: :agent,
                           configuration: { "agent_name" => "Test Agent" })
      end

      before do
        # Create edge from LLM component to agent
        create(:edge, workflow:, workspace:,
                      source_component: llm_component_db,
                      target_component: agent_component)
        # Reload to pick up the new edge
        llm_component_db.reload
      end

      it "returns true (should be executed in normal DAG flow)" do
        expect(component_with_db.executable?).to be true
      end
    end

    context "when component instance has no component record" do
      it "returns true (default behavior)" do
        expect(component.executable?).to be true
      end
    end
  end
end
