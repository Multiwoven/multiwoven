# frozen_string_literal: true

require "spec_helper"

RSpec.describe Multiwoven::Integrations::Source::MistralAi::Client do
  subject(:client) { described_class.new }

  let(:connection_config) do
    {
      url: "https://api.mistral.ai/v1/chat/completions",
      api_key: "test-key",
      request_format: "{\"model\":\"mistral-small-latest\", \"messages\":[{\"role\": \"user\", \"content\": \"Hi.\"}], \"stream\": false}",
      response_format: "{}",
      config: { timeout: "30" }
    }
  end

  it "reuses the GenericOpenAI client and loads MistralAi's own config" do
    expect(described_class).to be < Multiwoven::Integrations::Source::GenericOpenAI::Client
    expect(client.meta_data[:data][:name]).to eq("MistralAi")
    expect(client.connector_spec.connection_specification[:title]).to eq("MistralAi")
    expect(client.connector_spec.connector_query_type).to eq("ai_ml")
  end

  it "ships a curated MistralAi API catalog (OpenRouter mistralai ids do not match)" do
    expect(client.meta_data.dig(:data, :openrouter_slug)).to be_nil
    expect(Multiwoven::Integrations::Core::OpenRouterCatalog).not_to receive(:fetch)

    ids = client.model_catalog.models.map(&:id)
    expect(ids).to include(
      "mistral-large-latest",
      "mistral-medium-latest",
      "mistral-small-latest",
      "ministral-14b-latest",
      "ministral-8b-latest",
      "ministral-3b-latest",
      "codestral-latest"
    )
  end

  it "defaults request_format to mistral-small-latest" do
    default = client.connector_spec.connection_specification[:properties][:request_format][:default]
    expect(default).to include("mistral-small-latest")
  end

  it "discovers MistralAi's own catalog.json" do
    catalog = client.discover(nil).catalog

    expect(catalog.request_rate_limit).to eq(600)
    expect(catalog.request_rate_limit_unit).to eq("minute")
    expect(catalog.request_rate_concurrency).to eq(10)
    expect(catalog.streams).to eq([])
  end

  describe "#check_connection" do
    it "validates credentials" do
      response = Net::HTTPSuccess.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return('{"data":[]}')
      expect(client).to receive(:send_request).with(
        hash_including(
          url: "https://api.mistral.ai/v1/chat/completions",
          http_method: "POST",
          payload: JSON.parse(connection_config[:request_format]),
          headers: {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{connection_config[:api_key]}",
            "Content-Type" => "application/json"
          },
          config: connection_config[:config]
        )
      ).and_return(response)
      message = client.check_connection(connection_config)
      expect(message.connection_status.status).to eq("succeeded")
    end

    it "surfaces Rate limit exceeded" do
      response = Net::HTTPTooManyRequests.new("1.1", "429", "Too Many Requests")
      allow(response).to receive_messages(
        body: '{"message":"Rate limit exceeded","type":"rate_limit_exceeded"}',
        code: "429"
      )
      allow(client).to receive(:send_request).and_return(response)
      allow(client).to receive(:success?).with(response).and_return(false)

      message = client.check_connection(connection_config)
      expect(message.connection_status.status).to eq("failed")
      expect(message.connection_status.message).to eq("Rate limit exceeded")
    end
  end

  describe "#meta_data" do
    it "returns the correct meta data" do
      meta_data = client.send(:meta_data)
      meta_name = client.class.to_s.split("::")[-2]
      expect(meta_data).to be_a(Hash)
      expect(meta_data[:data][:name]).to eq(meta_name)
      expect(meta_data[:data][:connector_type]).to eq("source")
      expect(meta_data[:data][:icon]).to eq("https://res.cloudinary.com/dspflukeu/image/upload/v1790199623/Multiwoven/connectors/mistral_ai/icon.svg")
    end
  end
end
