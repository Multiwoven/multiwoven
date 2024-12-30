# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::DatabricksModel::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:mock_http_session) { double("Net::Http::Session") }

  let(:payload) do
    {
      messages: [
        {
          role: "user",
          content: "Hello there"
        }
      ]
    }
  end

  let(:sync_config_json) do
    {
      source: {
        name: "databrick-model-source",
        type: "source",
        connection_specification: {
          databricks_host: "test-host.databricks.com",
          token: "test_token",
          endpoint: "test",
          request_format: "{}",
          response_format: "{}"
        }
      },
      destination: {
        name: "DestinationConnectorName",
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

  before do
    allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
  end

  let(:headers) do
    {
      "Accept" => "application/json",
      "Authorization" => "Bearer test_token",
      "Content-Type" => "application/json"
    }
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      let(:response_body) { { "message" => "success" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "200", "Unauthorized")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with("https://test-host.databricks.com/api/2.0/serving-endpoints/test",
                "GET",
                headers: headers)
          .and_return(response)
      end

      it "returns a succeeded connection status" do
        message = client.check_connection(sync_config_json[:source][:connection_specification])
        result = message.connection_status
        expect(result).to be_a(Multiwoven::Integrations::Protocol::ConnectionStatus)
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      let(:response_body) { { "message" => "failed" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "401", "Unauthorized")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with("https://test-host.databricks.com/api/2.0/serving-endpoints/test",
                "GET",
                headers: headers)
          .and_return(response)
      end

      it "returns a failed connection status with an error message" do
        message = client.check_connection(sync_config_json[:source][:connection_specification])
        result = message.connection_status
        expect(result).to be_a(Multiwoven::Integrations::Protocol::ConnectionStatus)
        expect(result.status).to eq("failed")
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
        hash_including(context: "DATABRICKS MODEL:DISCOVER:EXCEPTION", type: "error")
      )
      client.discover
    end
  end

  describe "#read" do
    context "when the read is successful" do
      let(:response_body) do
        {
          "id": "chatcmpl_090b5500-1e59-4226-878c-2e1ec5e0b3d3",
          "object": "chat.completion",
          "created": 1_724_067_784,
          "model": "dbrx-instruct-071224",
          "choices": [
            {
              "index": 0,
              "message": {
                "role": "assistant",
                "content": "Hello! How can I assist you today?"
              }
            }
          ]
        }.to_json
      end
      before do
        response = Net::HTTPSuccess.new("1.1", "200", "Unauthorized")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with("https://test-host.databricks.com/serving-endpoints/test/invocations",
                "POST",
                payload: JSON.parse(payload.to_json),
                headers: headers)
          .and_return(response)
      end
      it "successfully reads records" do
        records = client.read(sync_config)
        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(records.first.record.data).to eq(JSON.parse(response_body))
      end
    end

    context "when the payload is invalid in read" do
      let(:response_body) { "{\"key\": invalid_json}" }.to_json
      before do
        response = Net::HTTPSuccess.new("1.1", "200", "Unauthorized")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with("https://test-host.databricks.com/serving-endpoints/test/invocations",
                "POST",
                payload: JSON.parse(payload.to_json),
                headers: headers)
          .and_return(response)
      end
      it "handles exceptions during reading" do
        records = client.read(sync_config)
        expect(records.log).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(records.log.message).to eq("parsing failed: please send a valid payload")
      end
    end

    context "when the read is failed" do
      it "handles exceptions during reading" do
        error_instance = StandardError.new("test error")
        allow(client).to receive(:run_model).and_raise(error_instance)
        expect(client).to receive(:handle_exception).with(
          error_instance,
          hash_including(context: "DATABRICKS MODEL:READ:EXCEPTION", type: "error")
        )

        client.read(sync_config)
      end
    end
  end
end
