# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Clickhouse::Client do # rubocop:disable Metrics/BlockLength
  let(:client) { Multiwoven::Integrations::Source::Clickhouse::Client.new }
  let(:sync_config) do
    {
      "source": {
        "name": "ClickHouseConnector",
        "type": "source",
        "connection_specification": {
          "url": "https://v8u38bthg0.us-east-2.aws.clickhouse.cloud:8443",
          "username": ENV["CLICKHOUSE_USERNAME"],
          "password": ENV["CLICKHOUSE_PASSWORD"],
          "database": "default"
        }
      },
      "destination": {
        "name": "DestinationConnectorName",
        "type": "destination",
        "connection_specification": {
          "example_destination_key": "example_destination_value"
        }
      },
      "model": {
        name: "test_table",
        query: "SELECT col1, col2, col3 FROM test_table",
        query_type: "raw_sql",
        primary_key: "id"
      },
      "stream": {
        "name": "example_stream", "action": "create",
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
      "destination_sync_mode": "upsert"
    }
  end

  let(:auth_token) { Base64.strict_encode64("#{sync_config[:source][:connection_specification][:username]}:#{sync_config[:source][:connection_specification][:password]}") }
  let(:faraday_connection) { instance_double(Faraday::Connection) }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(Base64).to receive(:strict_encode64).with("#{sync_config[:source][:connection_specification][:username]}:#{sync_config[:source][:connection_specification][:password]}").and_return(auth_token)
        allow(Faraday).to receive(:new).with(sync_config[:source][:connection_specification][:url]).and_return(faraday_connection)
        allow(client).to receive(:create_connection).with(sync_config[:source][:connection_specification]).and_return(faraday_connection)
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(client).to receive(:create_connection).and_raise(StandardError, "Connection failed")
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  # read and #discover tests for AWS Athena
  describe "#read" do
    it "reads records successfully" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      allow(Base64).to receive(:strict_encode64).with("#{sync_config[:source][:connection_specification][:username]}:#{sync_config[:source][:connection_specification][:password]}").and_return(auth_token)
      allow(Faraday).to receive(:new).with(sync_config[:source][:connection_specification][:url]).and_return(faraday_connection)
      allow(client).to receive(:create_connection).with(sync_config[:source][:connection_specification]).and_return(faraday_connection)
      allow(client).to receive(:query_execution).with(faraday_connection, sync_config[:model][:query]).and_return(
        [
          { "col1" => "value1", "col2" => "value2", "col3" => "value3" },
          { "col1" => "value4", "col2" => "value5", "col3" => "value6" }
        ]
      )
      records = client.read(s_config)
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "reads records successfully with limit" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      s_config.limit = 100
      s_config.offset = 1
      allow(Base64).to receive(:strict_encode64).with("#{sync_config[:source][:connection_specification][:username]}:#{sync_config[:source][:connection_specification][:password]}").and_return(auth_token)
      allow(Faraday).to receive(:new).with(sync_config[:source][:connection_specification][:url]).and_return(faraday_connection)
      expected_query = "#{sync_config[:model][:query]} LIMIT 100 OFFSET 1"
      allow(client).to receive(:create_connection).with(sync_config[:source][:connection_specification]).and_return(faraday_connection)
      allow(client).to receive(:query_execution).with(faraday_connection, expected_query).and_return(
        [
          { "col1" => "value1", "col2" => "value2", "col3" => "value3" },
          { "col1" => "value4", "col2" => "value5", "col3" => "value6" }
        ]
      )
      records = client.read(s_config)
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "read records failure" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      allow(client).to receive(:create_connection).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        "CLICKHOUSE:READ:EXCEPTION",
        "error",
        an_instance_of(StandardError)
      )
      client.read(s_config)
    end
  end

  describe "#discover" do
    it "discovers schema successfully" do
      allow(Base64).to receive(:strict_encode64).with("#{sync_config[:source][:connection_specification][:username]}:#{sync_config[:source][:connection_specification][:password]}").and_return(auth_token)
      allow(Faraday).to receive(:new).with(sync_config[:source][:connection_specification][:url]).and_return(faraday_connection)
      discovery_query = "SELECT table_name, column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema = '#{sync_config[:source][:connection_specification][:database]}' ORDER BY table_name, ordinal_position;"
      allow(client).to receive(:create_connection).with(sync_config[:source][:connection_specification]).and_return(faraday_connection)
      allow(client).to receive(:query_execution).with(faraday_connection, discovery_query).and_return(
        [
          { "table_name" => "test_table", "column_name" => "col1", "data_type" => "Nullable(Int32)", "is_nullable" => "1" },
          { "table_name" => "test_table", "column_name" => "col2", "data_type" => "Nullable(String)", "is_nullable" => "1" },
          { "table_name" => "test_table", "column_name" => "col3", "data_type" => "Nullable(Float32)", "is_nullable" => "1" }
        ]
      )
      message = client.discover(sync_config[:source][:connection_specification])
      expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
      first_stream = message.catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq("test_table")
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "col1" => { "type" => "string" } })
    end

    it "discover schema failure" do
      allow(client).to receive(:create_connection).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        "CLICKHOUSE:DISCOVER:EXCEPTION",
        "error",
        an_instance_of(StandardError)
      )
      client.discover(sync_config[:source][:connection_specification])
    end
  end

  describe "#meta_data" do
    # change this to rollout validation for all connector rolling out
    it "client class_name and meta name is same" do
      meta_name = client.class.to_s.split("::")[-2]
      expect(client.send(:meta_data)[:data][:name]).to eq(meta_name)
    end
  end

  describe "method definition" do
    it "defines a private #query method" do
      expect(described_class.private_instance_methods).to include(:query)
    end
  end
end
