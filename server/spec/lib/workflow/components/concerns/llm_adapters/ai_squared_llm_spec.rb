# frozen_string_literal: true

require "rails_helper"

RSpec.describe Workflow::Components::Concerns::LlmAdapters::AiSquaredLlm do
  let(:http_client) { class_double(Multiwoven::Integrations::Core::HttpClient) }
  let(:messages) { [{ role: "user", content: "Hello" }] }
  let(:chat_endpoint) { "https://bolt.example.com/chat" }
  let(:api_key) { "bolt-secret" }
  let(:response_body) do
    {
      "id" => "chatcmpl-test",
      "object" => "chat.completion",
      "model" => "aisquared/bolt-instruct-32b",
      "choices" => [{
        "index" => 0,
        "finish_reason" => "stop",
        "message" => { "role" => "assistant", "content" => "Hi there", "tool_calls" => [] }
      }],
      "usage" => { "prompt_tokens" => 10, "completion_tokens" => 5, "total_tokens" => 15 }
    }
  end
  let(:http_response) do
    instance_double(Net::HTTPSuccess, code: "200", body: response_body.to_json)
  end
  let(:request_headers) do
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{api_key}"
    }
  end

  subject(:llm) do
    described_class.new(
      base_url: chat_endpoint,
      http_client:,
      default_options: { temperature: 0.5, max_tokens: 128, chat_model: "aisquared/bolt-instruct-32b" }
    )
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("AISQUARED_BOLT_API_KEY", nil).and_return(api_key)
    allow(http_client).to receive(:request).and_return(http_response)
  end

  it "is recognized as an OpenAI LLM by Langchain" do
    expect(llm).to be_a(Langchain::LLM::OpenAI)
  end

  describe "#chat" do
    it "returns a Langchain OpenAIResponse" do
      expect(llm.chat(messages:)).to be_a(Langchain::LLM::OpenAIResponse)
    end

    it "posts the configured sampling payload to the endpoint" do
      expect(http_client).to receive(:request).with(
        chat_endpoint,
        "POST",
        payload: {
          "messages" => messages,
          "temperature" => 0.5,
          "max_tokens" => 128
        },
        headers: request_headers
      ).and_return(http_response)

      llm.chat(messages:)
    end

    it "returns the assistant message" do
      expect(llm.chat(messages:).chat_completion).to eq("Hi there")
    end

    it "includes tools in the payload when provided" do
      tools = [{ type: "function", function: { name: "search", description: "Search", parameters: {} } }]

      expect(http_client).to receive(:request).with(
        chat_endpoint,
        "POST",
        payload: hash_including("tools" => tools),
        headers: request_headers
      ).and_return(http_response)

      llm.chat(messages:, tools:)
    end

    it "uses AISQUARED_CHAT_ENDPOINT_URL when base_url is blank" do
      allow(ENV).to receive(:fetch).with("AISQUARED_CHAT_ENDPOINT_URL", nil)
                                   .and_return("https://env.example.com/chat")

      bare_llm = described_class.new(http_client:)

      expect(http_client).to receive(:request).with(
        "https://env.example.com/chat",
        "POST",
        hash_including(:payload, :headers)
      ).and_return(http_response)

      bare_llm.chat(messages:)
    end

    it "raises when AISQUARED_CHAT_ENDPOINT_URL is not configured" do
      allow(ENV).to receive(:fetch).with("AISQUARED_CHAT_ENDPOINT_URL", nil).and_return("  ")

      bare_llm = described_class.new(http_client:)
      expect { bare_llm.chat(messages:) }
        .to raise_error(described_class::Error, /AISQUARED_CHAT_ENDPOINT_URL/)
    end

    it "raises when AISQUARED_BOLT_API_KEY is not configured" do
      allow(ENV).to receive(:fetch).with("AISQUARED_BOLT_API_KEY", nil).and_return(nil)
      expect(http_client).not_to receive(:request)

      expect { llm.chat(messages:) }
        .to raise_error(described_class::Error, /AISQUARED_BOLT_API_KEY/)
    end

    it "raises when Lightning returns a non-success status" do
      allow(http_client).to receive(:request).and_return(
        instance_double(Net::HTTPResponse, code: "500", body: "boom")
      )

      expect { llm.chat(messages:) }
        .to raise_error(described_class::Error, /status 500/)
    end

    it "raises when Lightning returns invalid JSON" do
      allow(http_client).to receive(:request).and_return(
        instance_double(Net::HTTPSuccess, code: "200", body: "not-json")
      )

      expect { llm.chat(messages:) }
        .to raise_error(described_class::Error, /Failed to parse/)
    end

    context "when the model emits tool calls" do
      let(:response_body) do
        {
          "choices" => [{
            "index" => 0,
            "finish_reason" => "tool_calls",
            "message" => {
              "role" => "assistant",
              "content" => nil,
              "tool_calls" => [{
                "id" => "call_abc",
                "type" => "function",
                "function" => { "name" => "search", "arguments" => "{\"q\":\"x\"}" }
              }]
            }
          }],
          "usage" => { "prompt_tokens" => 1, "completion_tokens" => 1, "total_tokens" => 2 }
        }
      end

      it "surfaces OpenAI-shaped tool calls" do
        response = llm.chat(messages:)

        aggregate_failures do
          expect(response.tool_calls.first.dig("function", "name")).to eq("search")
          expect(response.chat_completion).to be_nil
        end
      end
    end
  end
end
