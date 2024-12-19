# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::OpenAI::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:mock_http_session) { double("Net::Http::Session") }
  let(:api_key) { "test_api_key" }
  let(:payload) do
    {
      queries: "Hello there"
    }
  end

  let(:sync_config_json) do
    {
      source: {
        name: "DestinationConnectorName",
        type: "destination",
        connection_specification: {
          api_key: api_key,
          config: {
            timeout: 25
          },
          request_format: payload.to_json
        }
      },
      destination: {
        name: "Http",
        type: "destination",
        connection_specification: {
          example_destination_key: "example_destination_value"
        }
      },
      model: {
        name: "ExampleModel",
        query: payload.to_json,
        query_type: "ai_ml",
        primary_key: "id"
      },
      stream: {
        name: "example_stream",
        json_schema: { "field1": "type1" },
        request_method: "POST",
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1
      },
      sync_mode: "full_refresh",
      cursor_field: "timestamp",
      destination_sync_mode: "upsert",
      sync_id: "1"
    }
  end

  let(:sync_config) { Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json) }
  let(:sync_config_stream) do
    sync_config_json[:source][:connection_specification][:is_stream] = true
    Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
  end
  before do
    allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
  end
  let(:headers) do
    {
      "Accept" => "application/json",
      "Authorization" => "Bearer #{api_key}",
      "Content-Type" => "application/json"
    }
  end
  let(:endpoint) { "https://api.openai.com/v1/chat/completions" }

  describe "#check_connection" do
    context "when the connection is successful" do
      let(:response_body) { { "message" => "success" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "200", "Unauthorized")
        response.content_type = "application/json"
        config = sync_config_json[:source][:connection_specification][:config]
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(endpoint,
                "POST",
                payload: JSON.parse(payload.to_json),
                headers: headers,
                config: config)
          .and_return(response)
      end

      it "returns a successful connection status" do
        response = client.check_connection(sync_config_json[:source][:connection_specification])
        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("succeeded")
      end
    end

    context "when the connection fails" do
      let(:response_body) { { "message" => "failed" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "401", "Unauthorized")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(endpoint,
                "POST",
                headers: headers)
          .and_return(response)
      end

      it "returns a failed connection status with an error message" do
        response = client.check_connection(sync_config_json[:source][:connection_specification])

        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("failed")
      end
    end
  end

  describe "#discover" do
    it "successfully returns the catalog message" do
      message = client.discover(nil)
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.request_rate_limit).to eql(600)
      expect(catalog.request_rate_limit_unit).to eql("minute")
      expect(catalog.request_rate_concurrency).to eql(10)
    end

    it "handles exceptions during discovery" do
      allow(client).to receive(:read_json).and_raise(StandardError.new("test error"))
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError),
        hash_including(context: "OPEN AI:DISCOVER:EXCEPTION", type: "error")
      )
      client.discover
    end
  end

  describe "#read" do
    context "when the read is successful" do
      let(:response_body) { { "message" => "Hello! how can I help" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "200", "success")
        response.content_type = "application/json"
        config = sync_config_json[:source][:connection_specification][:config]
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(endpoint,
                "POST",
                payload: JSON.parse(payload.to_json),
                headers: headers,
                config: config)
          .and_return(response)
      end

      it "successfully reads records" do
        records = client.read(sync_config)
        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(records.first.record.data).to eq(JSON.parse(response_body))
      end
    end

    context "when the read operation fails" do
      let(:response_body) { { "message" => "failed" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "401", "Unauthorized")
        response.content_type = "application/json"
        config = sync_config_json[:source][:connection_specification][:config]
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(endpoint,
                "POST",
                headers: headers,
                config: config)
          .and_return(response)
      end

      it "handles exceptions during reading" do
        error_instance = StandardError.new("test error")
        allow(client).to receive(:run_model).and_raise(error_instance)
        expect(client).to receive(:handle_exception).with(
          error_instance,
          hash_including(context: "OPEN AI:READ:EXCEPTION", type: "error")
        )

        client.read(sync_config)
      end
    end
  end

  describe "#read with is_stream = true" do
    context "when the read is successful" do
      before do
        payload = sync_config_json[:model][:query]
        streaming_chunk_first = <<~DATA
          data: {"choices":[{"delta":{"content":"How I "}}]}

          data: {"choices":[{"delta":{"content":"can help "}}]}
        DATA
        streaming_chunk_second = "data: {\"choices\":[{\"delta\":{\"content\":\"you\"}}]}\n\n"

        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
          .with(endpoint,
                "POST",
                payload: JSON.parse(payload),
                headers: headers,
                config: sync_config_json[:source][:connection_specification][:config])
          .and_yield(streaming_chunk_first)
          .and_yield(streaming_chunk_second)

        response = Net::HTTPSuccess.new("1.1", "200", "success")
        response.content_type = "application/json"
      end

      it "streams data and processes chunks" do
        results = []
        client.read(sync_config_stream) { |message| results << message }
        expect(results.first).to be_an(Array)
        expect(results.first.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(results.first.first.record.data.dig("choices", 0, "delta", "content")).to eq("How I ")

        expect(results[1]).to be_an(Array)
        expect(results[1].first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(results[1].first.record.data.dig("choices", 0, "delta", "content")).to eq("can help ")

        expect(results[2]).to be_an(Array)
        expect(results[2].first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(results[2].first.record.data.dig("choices", 0, "delta", "content")).to eq("you")
      end
    end

    context "when streaming fails on a chunk" do
      let(:streaming_chunk_first) { { "message" => "streaming data chunk 1" }.to_json }

      before do
        config = sync_config_json[:source][:connection_specification][:config]
        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
          .with(endpoint,
                "POST",
                payload: JSON.parse(payload.to_json),
                headers: headers,
                config: config)
          .and_yield(streaming_chunk_first)
          .and_raise(StandardError, "Streaming error on chunk 2")
      end

      it "handles streaming errors gracefully" do
        results = []
        client.read(sync_config_stream) { |message| results << message }
        expect(results.last).to be_an(Array)
        expect(results.last.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(results.last.first.record.data["message"]).to eq("streaming data chunk 1")
      end
    end
  end
end
