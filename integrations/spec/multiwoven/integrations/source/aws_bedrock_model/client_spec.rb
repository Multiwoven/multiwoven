# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::AwsBedrockModel::Client do
  let(:client) { Multiwoven::Integrations::Source::AwsBedrockModel::Client.new }
  let(:payload) do
    {
      prompt: "\n\nHuman: Hi\n\nAssistant:",
      max_tokens_to_sample: 10,
      anthropic_version: "bedrock-2023-05-31"
    }
  end
  let(:sync_config) do
    {
      "source": {
        "name": "AWS Bedrock Model",
        "type": "source",
        "connection_specification": {
          "access_key": ENV["ATHENA_ACCESS"],
          "secret_access_key": ENV["ATHENA_SECRET"],
          "region": "us-east-1",
          "model_id": "anthropic.claude-instant-v1",
          "request_format": {},
          "response_format": {}
        }
      },
      "destination": {
        "name": "Sample Destination Connector",
        "type": "destination",
        "connection_specification": {
          "example_destination_key": "example_destination_value"
        }
      },
      "model": {
        "name": "Bedrock Account",
        "query": payload.to_json,
        "query_type": "raw_sql",
        "primary_key": "id"
      },
      "stream": {
        "name": "example_stream",
        "action": "create",
        "json_schema": { "field1": "type1" },
        "supported_sync_modes": %w[full_refresh incremental],
        "source_defined_cursor": true,
        "default_cursor_field": ["field1"],
        "source_defined_primary_key": [["field1"], ["field2"]],
        "namespace": "exampleNamespace",
        "url": "https://api.example.com/data",
        "method": "GET"
      },
      "sync_mode": "full_refresh",
      "cursor_field": "timestamp",
      "destination_sync_mode": "upsert",
      "sync_id": "1"
    }
  end

  let(:runtime_client) { instance_double(Aws::BedrockRuntime::Client) }
  let(:body_double) { instance_double(StringIO, read: "{\"type\":\"completion\",\"completion\":\" Hello!\",\"stop_reason\":\"stop_sequence\",\"stop\":\"\\n\\nHuman:\"}") }
  let(:response) { double(body: body_double) }

  describe "#check_connection" do
    before do
      allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(runtime_client)
      allow(runtime_client).to receive(:invoke_model).and_return(response)
    end
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow_any_instance_of(Multiwoven::Integrations::Source::AwsBedrockModel::Client).to receive(:create_connection).and_raise(StandardError, "Connection failed")
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
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
        hash_including(context: "AWS:BEDROCK MODEL:DISCOVER:EXCEPTION", type: "error")
      )
      client.discover(nil)
    end
  end

  # read and #discover tests for AWS Athena
  describe "#read" do
    context "when the read is successful" do
      it "reads records successfully" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(runtime_client)
        allow(runtime_client).to receive(:invoke_model).and_return(response)
        records = client.read(s_config)
        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(records.first.record.data).to eq(
          {
            "type" => "completion",
            "completion" => " Hello!",
            "stop_reason" => "stop_sequence",
            "stop" => "\n\nHuman:"
          }
        )
      end
    end

    context "when the read is successful" do
      it "reads records successfully" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        s_config[:source][:connection_specification][:model_id] = "mistral.mistral-large-2402-v1:0"
        allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(runtime_client)
        allow(runtime_client).to receive(:invoke_model).and_return(response)
        records = client.read(s_config)
        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(records.first.record.data).to eq(
          {
            "type" => "completion",
            "completion" => " Hello!",
            "stop_reason" => "stop_sequence",
            "stop" => "\n\nHuman:"
          }
        )
      end
    end

    context "when the read is failed" do
      it "handles exceptions during reading" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        error_instance = StandardError.new("test error")
        allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(runtime_client)
        allow(client).to receive(:run_model).and_raise(error_instance)
        expect(client).to receive(:handle_exception).with(
          error_instance,
          {
            context: "AWS:BEDROCK MODEL:READ:EXCEPTION",
            sync_id: "1",
            sync_run_id: nil,
            type: "error"
          }
        )
        client.read(s_config)
      end
    end
  end
end
