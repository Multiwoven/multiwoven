# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::PineconeDB::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      region: "us-east-1",
      api_key: "test_key",
      index_name: "test"
    }
  end
  let(:sync_config_json) do
    {
      source: {
        name: "Sample Source Connector",
        type: "source",
        connection_specification: {
          private_api_key: "test_api_key"
        }
      },
      destination: {
        name: "PineconeDB",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT col1, col2, col3 FROM test_table_1",
        query_type: "raw_sql",
        primary_key: "col1"
      },
      sync_mode: "incremental",
      destination_sync_mode: "insert",
      stream: {
        name: "test_table.xlsx, sheet",
        action: "create",
        json_schema: {
          type: "object",
          additionalProperties: true,
          required: %w[id text],
          properties: {
            id: {
              type: "string"
            },
            vector: {
              type: "vector"
            },
            text: {
              type: "string"
            },
            meta_data: {
              type: "string"
            }
          }
        },
        supported_sync_modes: %w[incremental],
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1
      }
    }
  end

  let(:pinecone_client) { double("Pinecone::Client") }
  let(:pinecone_index) { double("Pinecone::Index") }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(client).to receive(:create_connection)
        allow(pinecone_client).to receive(:describe_index).and_return({ name: "test" })

        client.instance_variable_set(:@pinecone, pinecone_client)
        client.instance_variable_set(:@index_name, "test")

        message = client.check_connection(sync_config_json[:destination][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(client).to receive(:create_connection).and_raise(StandardError, "Connection failed")
        message = client.check_connection(sync_config_json[:destination][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  describe "#discover" do
    it "discovers schema successfully" do
      mock_response = double("Response", body: {
        "namespaces" => {
          "Record" => {}
        }
      }.to_json)

      allow(Pinecone::Client).to receive(:new).and_return(pinecone_client)
      allow(pinecone_client).to receive(:index).with("test").and_return(pinecone_index)
      allow(pinecone_index).to receive(:describe_index_stats).and_return(mock_response)

      # Set internal state (you could also call client.discover(connection_config))
      client.instance_variable_set(:@pinecone, pinecone_client)
      client.instance_variable_set(:@index_name, "test")
      client.instance_variable_set(:@api_key, "test_key")
      client.instance_variable_set(:@region, "us-east-1")

      message = client.discover(sync_config_json[:destination][:connection_specification])
      expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
      first_stream = message.catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq("Record")
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "id" => { "type" => "string" }, "value" => { "type" => "vector" }, "meta_data" => { "type" => "string" } })
    end
  end

  describe "#write" do
    context "when the write operation is successful" do
      it "increments the success count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
        records = [{
          "id" => "400",
          "text" => "Fourth",
          "meta_data" => '{"source":"test"}',
          "vector" => [0.1, 0.2, 0.3]
        }]
        mock_response = double("PineconeResponse", code: 200, to_h: { "upsertedCount" => 1 })

        allow(Pinecone::Client).to receive(:new).and_return(pinecone_client)
        allow(pinecone_client).to receive(:index).with("test").and_return(pinecone_index)
        allow(pinecone_index).to receive(:upsert).and_return(mock_response)

        client.instance_variable_set(:@pinecone, pinecone_client)
        client.instance_variable_set(:@index_name, "test")
        client.instance_variable_set(:@api_key, "test_key")
        client.instance_variable_set(:@region, "us-east-1")

        message = client.write(sync_config, records)
        tracker = message.tracking

        expect(tracker.success).to eq(records.count)
        expect(tracker.failed).to eq(0)

        log_message = message.tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("info")
        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end
    end

    context "when the write operation fails" do
      it "increments the failure count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
        records = [{
          "id" => "400",
          "text" => "Fourth",
          "meta_data" => '{"source":"test"}',
          "vector" => [0.1, 0.2, 0.3]
        }]

        allow(Pinecone::Client).to receive(:new).and_return(pinecone_client)
        allow(pinecone_client).to receive(:index).with("test").and_raise(StandardError.new("Client down"))

        client.instance_variable_set(:@pinecone, pinecone_client)
        client.instance_variable_set(:@index_name, "test")
        client.instance_variable_set(:@api_key, "test_key")
        client.instance_variable_set(:@region, "us-east-1")

        message = client.write(sync_config, records)
        tracker = message.tracking

        expect(tracker.success).to eq(0)
        expect(tracker.failed).to eq(1)

        log_message = tracker.logs.first
        expect(log_message.level).to eql("error")
        expect(log_message.message).to include("Client down")
      end
    end
  end

  describe "#meta_data" do
    # change this to rollout validation for all connector rolling out
    it "client class_name and meta name is same" do
      meta_name = client.class.to_s.split("::")[-2]
      expect(client.send(:meta_data)[:data][:name]).to eq(meta_name)
    end
  end
end
