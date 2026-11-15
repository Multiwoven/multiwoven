# frozen_string_literal: true

require "rails_helper"

RSpec.describe Workflow::Components::Concerns::LlmProviderAdapter do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include Workflow::Components::Concerns::LlmProviderAdapter

      attr_accessor :workflow_run

      def initialize(workflow_run)
        @workflow_run = workflow_run
      end
    end
  end

  let(:workspace) { create(:workspace) }
  let(:workflow) { create(:workflow, workspace:) }
  let(:workflow_run) { create(:workflow_run, workflow:, workspace:, id: 123) }
  let(:instance) { test_class.new(workflow_run) }

  let(:messages) do
    [
      { "role" => "user", "content" => "Hello, how are you?" }
    ]
  end

  let(:system_instruction) { "You are a helpful assistant." }

  describe "#build_llm_payload" do
    context "for OpenAI connector" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_name: "OpenAI",
               connector_type: :source,
               configuration: { "request_format" => request_format.to_json })
      end

      let(:request_format) do
        { "model" => "gpt-4o-mini", "temperature" => 0.7, "max_tokens" => 2000 }
      end

      it "builds OpenAI-formatted payload" do
        result = instance.build_llm_payload(connector, messages, system_instruction)

        expect(result["model"]).to eq("gpt-4o-mini")
        expect(result["messages"]).to be_an(Array)
        expect(result["messages"].length).to eq(2) # system + user
        expect(result["messages"].first["role"]).to eq("system")
        expect(result["messages"].first["content"]).to eq(system_instruction)
        expect(result["messages"].last["role"]).to eq("user")
        expect(result["temperature"]).to eq(0.7)
        expect(result["max_tokens"]).to eq(2000)
      end

      it "does not add duplicate system message if already present" do
        messages_with_system = [
          { "role" => "system", "content" => "Existing system message" },
          { "role" => "user", "content" => "Hello" }
        ]

        result = instance.build_llm_payload(connector, messages_with_system, system_instruction)

        system_messages = result["messages"].select { |m| m["role"] == "system" }
        expect(system_messages.length).to eq(1)
      end
    end

    context "for Anthropic connector" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_name: "Anthropic",
               connector_type: :source,
               configuration: { "request_format" => request_format.to_json, "max_tokens" => 3000 })
      end

      let(:request_format) do
        { "model" => "claude-opus-4-5-20251101", "max_tokens" => 4096 }
      end

      it "builds Anthropic-formatted payload with top-level system parameter" do
        result = instance.build_llm_payload(connector, messages, system_instruction)

        expect(result["model"]).to eq("claude-opus-4-5-20251101")
        expect(result["system"]).to eq(system_instruction)
        expect(result["messages"]).to be_an(Array)
        expect(result["messages"].length).to eq(1) # only user message
        expect(result["messages"].first["role"]).to eq("user")
        expect(result["max_tokens"]).to eq(4096)
      end

      it "extracts system messages from messages array" do
        messages_with_system = [
          { "role" => "system", "content" => "System from history" },
          { "role" => "user", "content" => "Hello" }
        ]

        result = instance.build_llm_payload(connector, messages_with_system, system_instruction)

        expect(result["system"]).to include("System from history")
        expect(result["system"]).to include(system_instruction)
        expect(result["messages"].none? { |m| m["role"] == "system" }).to be true
      end

      it "uses default max_tokens if not specified" do
        connector.configuration.delete("max_tokens")
        request_format.delete("max_tokens")
        connector.configuration["request_format"] = request_format.to_json

        result = instance.build_llm_payload(connector, messages, system_instruction)

        expect(result["max_tokens"]).to eq(4096)
      end
    end

    context "for AWS Bedrock connector with Anthropic model" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_name: "AwsBedrockModel",
               connector_type: :source,
               configuration: { "request_format" => request_format.to_json })
      end

      let(:request_format) do
        { "model" => "anthropic.claude-sonnet-4-20250514-v1:0", "max_tokens" => 2048 }
      end

      it "uses Anthropic format for Anthropic models on Bedrock" do
        result = instance.build_llm_payload(connector, messages, system_instruction)

        expect(result["model"]).to eq("anthropic.claude-sonnet-4-20250514-v1:0")
        expect(result["system"]).to eq(system_instruction)
        expect(result["messages"].none? { |m| m["role"] == "system" }).to be true
        expect(result["max_tokens"]).to eq(2048)
      end
    end

    context "for AWS Bedrock connector with Titan model" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_name: "AwsBedrockModel",
               connector_type: :source,
               configuration: { "request_format" => request_format.to_json })
      end

      let(:request_format) do
        { "model" => "amazon.titan-text-express-v1", "max_tokens" => 1024 }
      end

      it "uses standard format for non-Anthropic models on Bedrock" do
        result = instance.build_llm_payload(connector, messages, system_instruction)

        expect(result["model"]).to eq("amazon.titan-text-express-v1")
        expect(result["messages"].first["role"]).to eq("system")
        expect(result["messages"].first["content"]).to eq(system_instruction)
        expect(result["max_tokens"]).to eq(1024)
      end
    end

    context "for GenericOpenAI connector" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_name: "GenericOpenAI",
               connector_type: :source,
               configuration: { "request_format" => request_format.to_json })
      end

      let(:request_format) do
        { "model" => "custom-model-v1" }
      end

      it "uses OpenAI format" do
        result = instance.build_llm_payload(connector, messages, system_instruction)

        expect(result["model"]).to eq("custom-model-v1")
        expect(result["messages"].first["role"]).to eq("system")
        expect(result["messages"].first["content"]).to eq(system_instruction)
      end
    end

    context "for Aisquared connector" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_name: "Aisquared",
               connector_type: :source,
               configuration: { "request_format" => request_format.to_json })
      end

      let(:request_format) do
        { "temperature" => 0.7, "max_tokens" => 256 }
      end

      it "builds Aisquared-formatted payload without a model field" do
        result = instance.build_llm_payload(connector, messages, system_instruction)

        expect(result).not_to have_key("model")
        expect(result["messages"]).to eq(messages)
        expect(result["messages"].length).to eq(1)
        expect(result["messages"].first["role"]).to eq("user")
        expect(result["messages"].first["content"]).to eq("Hello, how are you?")
        expect(result["temperature"]).to eq(0.7)
        expect(result["max_tokens"]).to eq(256)
      end

      it "passes messages through without injecting a system message" do
        messages_with_system = [
          { "role" => "system", "content" => "Existing system message" },
          { "role" => "user", "content" => "Hello" }
        ]

        result = instance.build_llm_payload(connector, messages_with_system, system_instruction)

        expect(result["messages"]).to eq(messages_with_system)
        expect(result["messages"].length).to eq(2)
        expect(result["messages"].first["content"]).to eq("Existing system message")
      end

      it "omits optional parameters not present in request_format" do
        connector.configuration["request_format"] = {}.to_json

        result = instance.build_llm_payload(connector, messages, system_instruction)

        expect(result).not_to have_key("temperature")
        expect(result).not_to have_key("max_tokens")
      end
    end

    context "error handling" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_name: "OpenAI",
               connector_type: :source,
               configuration: {})
      end

      context "when request_format is nil" do
        before do
          connector.configuration["request_format"] = nil
        end

        it "raises clear error message" do
          expect do
            instance.build_llm_payload(connector, messages, system_instruction)
          end.to raise_error(StandardError, /Missing request_format in connector configuration for OpenAI/)
        end
      end

      context "when request_format is blank string" do
        before do
          connector.configuration["request_format"] = ""
        end

        it "raises clear error message" do
          expect do
            instance.build_llm_payload(connector, messages, system_instruction)
          end.to raise_error(StandardError, /Missing request_format in connector configuration for OpenAI/)
        end
      end

      context "when request_format contains invalid JSON" do
        before do
          connector.configuration["request_format"] = "not valid json"
        end

        it "raises clear error message with JSON parse error" do
          expect do
            instance.build_llm_payload(connector, messages, system_instruction)
          end.to raise_error(StandardError, /Invalid JSON in request_format for OpenAI/)
        end
      end

      context "when request_format contains malformed JSON" do
        before do
          connector.configuration["request_format"] = '{"model": "gpt-4", invalid}'
        end

        it "raises clear error message with parse details" do
          expect do
            instance.build_llm_payload(connector, messages, system_instruction)
          end.to raise_error(StandardError, /Invalid JSON in request_format for OpenAI/)
        end
      end

      context "for Anthropic connector with invalid JSON" do
        let(:anthropic_connector) do
          create(:connector,
                 workspace:,
                 connector_name: "Anthropic",
                 connector_type: :source,
                 configuration: { "request_format" => "invalid json" })
        end

        it "includes provider name in error message" do
          expect do
            instance.build_llm_payload(anthropic_connector, messages, system_instruction)
          end.to raise_error(StandardError, /Invalid JSON in request_format for Anthropic/)
        end
      end
    end
  end

  describe "#extract_llm_response" do
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

    let(:mock_record) { double("record", data: response_data, present?: true) }
    let(:mock_response) { [double("response_item", record: mock_record)] }

    context "for OpenAI connector" do
      let(:connector) { create(:connector, workspace:, connector_name: "OpenAI", connector_type: :source) }

      it "extracts response from OpenAI format" do
        result = instance.extract_llm_response(mock_response, connector)
        expect(result).to eq("I'm doing well, thank you!")
      end
    end

    context "for Anthropic connector" do
      let(:connector) { create(:connector, workspace:, connector_name: "Anthropic", connector_type: :source) }
      let(:response_data) do
        {
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
          "stop_reason" => "end_turn",
          "usage" => {
            "input_tokens" => 16,
            "output_tokens" => 21
          }
        }
      end

      it "extracts response from Anthropic format" do
        result = instance.extract_llm_response(mock_response, connector)
        expect(result).to eq("I'm doing well, thank you!")
      end

      it "handles multiple content blocks" do
        multi_content_data = response_data.dup
        multi_content_data["content"] = [
          { "type" => "text", "text" => "First block. " },
          { "type" => "text", "text" => "Second block." }
        ]
        multi_response = [double("response_item", record: double("record", data: multi_content_data, present?: true))]
        result = instance.extract_llm_response(multi_response, connector)
        expect(result).to eq("First block. ")
      end
    end

    context "for AWS Bedrock connector" do
      let(:connector) { create(:connector, workspace:, connector_name: "AwsBedrockModel", connector_type: :source) }

      it "extracts response from Bedrock format" do
        result = instance.extract_llm_response(mock_response, connector)
        expect(result).to eq("I'm doing well, thank you!")
      end
    end

    context "for GenericOpenAI connector" do
      let(:connector) { create(:connector, workspace:, connector_name: "GenericOpenAI", connector_type: :source) }

      it "extracts response from GenericOpenAI format" do
        result = instance.extract_llm_response(mock_response, connector)
        expect(result).to eq("I'm doing well, thank you!")
      end
    end

    context "for Aisquared connector" do
      let(:connector) { create(:connector, workspace:, connector_name: "Aisquared", connector_type: :source) }

      it "extracts response from Aisquared chat completion format" do
        result = instance.extract_llm_response(mock_response, connector)
        expect(result).to eq("I'm doing well, thank you!")
      end
    end

    context "when response is invalid" do
      let(:connector) { create(:connector, workspace:, connector_name: "OpenAI", connector_type: :source) }
      let(:invalid_response) { [double("response_item", record: nil)] }

      it "returns nil" do
        result = instance.extract_llm_response(invalid_response, connector)
        expect(result).to be_nil
      end
    end
  end

  describe "#combine_system_messages" do
    it "combines multiple system messages" do
      system_messages = [
        { "role" => "system", "content" => "First system message" },
        { "role" => "system", "content" => "Second system message" }
      ]

      result = instance.send(:combine_system_messages, system_messages, system_instruction)

      expect(result).to include("First system message")
      expect(result).to include("Second system message")
      expect(result).to include(system_instruction)
    end

    it "handles empty system messages array" do
      result = instance.send(:combine_system_messages, [], system_instruction)

      expect(result).to eq(system_instruction)
    end

    it "filters out blank messages" do
      system_messages = [
        { "role" => "system", "content" => "" },
        { "role" => "system", "content" => "Valid message" }
      ]

      result = instance.send(:combine_system_messages, system_messages, system_instruction)

      expect(result).to include("Valid message")
      expect(result).to include(system_instruction)
      expect(result).not_to match(/\n\n\n/) # No triple newlines from blank content
    end
  end

  describe "#extract_max_tokens" do
    let(:connector) do
      create(:connector,
             workspace:,
             connector_name: "OpenAI",
             connector_type: :source,
             configuration: { "max_tokens" => 5000 })
    end

    it "extracts max_tokens from request" do
      request = { "max_tokens" => 1000 }
      result = instance.send(:extract_max_tokens, request, connector)
      expect(result).to eq(1000)
    end

    it "falls back to connector configuration" do
      request = {}
      result = instance.send(:extract_max_tokens, request, connector)
      expect(result).to eq(5000)
    end

    it "uses default if neither specified" do
      request = {}
      connector.configuration.delete("max_tokens")
      result = instance.send(:extract_max_tokens, request, connector)
      expect(result).to eq(4096)
    end
  end

  describe "#check_llm_response_for_errors" do
    context "when response contains error LogMessage" do
      let(:log_message) do
        Multiwoven::Integrations::Protocol::LogMessage.new(
          message: "API request failed: Invalid API key",
          level: "error"
        )
      end
      let(:message) { double("message", log: log_message) }

      it "raises an error with the log message" do
        expect { instance.send(:check_llm_response_for_errors, message, workflow_run.id) }
          .to raise_error("LLM API request failed: API request failed: Invalid API key")
      end
    end

    context "when response contains error LogMessage with blank message" do
      let(:log_message) do
        Multiwoven::Integrations::Protocol::LogMessage.new(
          message: "",
          level: "error"
        )
      end
      let(:message) { double("message", log: log_message) }

      it "raises an error with default message" do
        expect { instance.send(:check_llm_response_for_errors, message, workflow_run.id) }
          .to raise_error("LLM API request failed: Unknown error")
      end
    end

    context "when response has non-error LogMessage" do
      let(:log_message) do
        Multiwoven::Integrations::Protocol::LogMessage.new(
          message: "Info message",
          level: "info"
        )
      end
      let(:message) { double("message", log: log_message) }

      it "does not raise an error" do
        expect { instance.send(:check_llm_response_for_errors, message, workflow_run.id) }.not_to raise_error
      end
    end

    context "when message has no log" do
      let(:message) { double("message", log: nil) }

      it "does not raise an error" do
        expect { instance.send(:check_llm_response_for_errors, message, workflow_run.id) }.not_to raise_error
      end
    end
  end
end
