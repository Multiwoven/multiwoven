# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::MariaDB::Client do
  let(:client) { Multiwoven::Integrations::Source::MariaDB::Client.new }
  let(:sync_config) do
    {
      "source": {
        "name": "ClickHouseConnector",
        "type": "source",
        "connection_specification": {
          "host": "127.0.0.1",
          "port": "3306",
          "username": "Test_service",
          "password": ENV["MARIADB_PASSWORD"],
          "database": "test_database"
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
        "name": "MariaDB Model",
        "query": "SELECT col1, col2, col3 FROM test_table",
        "query_type": "raw_sql",
        "primary_key": "id"
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
      "destination_sync_mode": "upsert",
      "sync_id": "1"
    }
  end

  let(:sequel_client) { instance_double(Sequel::Database) }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow_any_instance_of(Multiwoven::Integrations::Source::MariaDB::Client).to receive(:create_connection).and_return(sequel_client)
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow_any_instance_of(Multiwoven::Integrations::Source::MariaDB::Client).to receive(:create_connection).and_raise(StandardError, "Connection failed")
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  # read and #discover tests for MariaDB
  describe "#read" do
    it "reads records successfully" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      dataset = double("Sequel::Dataset")
      allow(dataset).to receive(:all).and_return(
        [
          { col1: 1, col2: "First Row Text", col3: "First Row Additional Text" },
          { col1: 1, col2: "Second Row Text", col3: "Second Row Additional Text" },
          { col1: 1, col2: "Third Row Text", col3: "Third Row Additional Text" }
        ]
      )
      allow(sequel_client).to receive(:fetch).and_return(dataset)
      allow(client).to receive(:create_connection).and_return(sequel_client)
      records = client.read(s_config)
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "reads records successfully with limit" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      s_config.limit = 100
      s_config.offset = 1
      dataset = double("Sequel::Dataset")
      allow(dataset).to receive(:all).and_return(
        [
          { col1: 1, col2: "First Row Text", col3: "First Row Additional Text" },
          { col1: 1, col2: "Second Row Text", col3: "Second Row Additional Text" },
          { col1: 1, col2: "Third Row Text", col3: "Third Row Additional Text" }
        ]
      )
      allow(sequel_client).to receive(:fetch).and_return(dataset)
      allow(client).to receive(:create_connection).and_return(sequel_client)
      records = client.read(s_config)
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "read records failure" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      s_config.sync_run_id = "2"
      allow(client).to receive(:create_connection).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError), {
          context: "MARIA:DB:READ:EXCEPTION",
          type: "error",
          sync_id: "1",
          sync_run_id: "2"
        }
      )
      client.read(s_config)
    end
  end

  describe "#discover" do
    it "discovers schema successfully" do
      dataset = double("Sequel::Dataset")
      allow(dataset).to receive(:all).and_return(
        [
          { table_name: "test_table", column_name: "col1", data_type: "int", is_nullable: "YES" },
          { table_name: "test_table", column_name: "col2", data_type: "varchar", is_nullable: "YES" },
          { table_name: "test_table", column_name: "col3", data_type: "float", is_nullable: "YES" }
        ]
      )
      allow(sequel_client).to receive(:fetch).and_return(dataset)
      allow(client).to receive(:create_connection).and_return(sequel_client)

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
        an_instance_of(StandardError), {
          context: "MARIA:DB:DISCOVER:EXCEPTION",
          type: "error"
        }
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
