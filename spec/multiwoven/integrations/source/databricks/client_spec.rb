# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Databricks::Client do # rubocop:disable Metrics/BlockLength
  let(:client) { Multiwoven::Integrations::Source::Databricks::Client.new }

  let(:sync_config_json) do
    {
      "source": {
        "name": "databrick-source",
        "type": "source",
        "connection_specification": {
          "host": "test-host.databricks.com",
          "http_path": "test_http_path",
          "access_token": "test_toekn",
          "port": "443",
          "catalog": "system",
          "schema": "information_schema"
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
        "name": "ExampleModel",
        "query": "SELECT * FROM samples.nyctaxi.trips;",
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
      "destination_sync_mode": "upsert"
    }
  end

  let(:sync_config) { Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json) }

  describe "method definition" do
    it "defines a private #query method" do
      expect(described_class.private_instance_methods).to include(:query)
    end
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(Sequel).to receive(:odbc).and_return(true)

        result = client.check_connection(sync_config_json[:source][:connection_specification])
        expect(result.type).to eq("connection_status")

        connection_status = result.connection_status
        expect(connection_status.status).to eq("succeeded")
        expect(connection_status.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(Sequel).to receive(:odbc).and_raise(Sequel::DatabaseConnectionError, "Connection failed")

        result = client.check_connection(sync_config_json[:source][:connection_specification])
        expect(result.type).to eq("connection_status")

        connection_status = result.connection_status
        expect(connection_status.status).to eq("failed")
        expect(connection_status.message).to eq("Connection failed")
      end
    end
  end

  describe "#discover" do
    it "discover schema successfully" do
      allow(Sequel).to receive(:odbc).and_return(double("db").as_null_object)
      allow_any_instance_of(RSpec::Mocks::Double).to receive(:fetch).and_yield(
        table_name: "TEST_TABLE",
        column_name: "ID",
        data_type: "NUMBER",
        is_nullable: "YES"
      )

      message = client.discover(sync_config[:source][:connection_specification])

      expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)

      first_stream = message.catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq("TEST_TABLE")
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "ID" => { "type" => %w[integer null] } })
    end

    it "discover schema failure" do
      allow(client).to receive(:create_connection).and_raise(StandardError.new("test error"))
      expect(client).to receive(:handle_exception).with(
        "DATABRICKS:DISCOVER:EXCEPTION",
        "error",
        an_instance_of(StandardError)
      )
      client.discover(sync_config[:source][:connection_specification])
    end
  end

  describe "#read" do
    it "reads records successfully" do
      allow(Sequel).to receive(:odbc).and_return(double("db").as_null_object)

      allow_any_instance_of(RSpec::Mocks::Double).to receive(:fetch).with(sync_config.model.query).and_yield(id: 1, name: "John").and_yield(id: 2, name: "Jane")

      records = client.read(sync_config)

      expect(records).to be_an(Array)
      expect(records.length).to eq(2)

      multiwoven_message = records.first
      first_record = multiwoven_message.record
      expect(first_record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
      expect(first_record.data).to eq(id: 1, name: "John")
      expect(first_record.emitted_at).to be_an(Integer)
    end

    it "reads records successfully for batched_query" do
      allow(Sequel).to receive(:odbc).and_return(double("db").as_null_object)

      sync_config.limit = "10"
      sync_config.offset = "1"

      batched_query = client.send(:batched_query, sync_config.model.query, sync_config.limit, sync_config.offset)

      allow_any_instance_of(RSpec::Mocks::Double).to receive(:fetch).with(batched_query).and_yield(id: 1, name: "John").and_yield(id: 2, name: "Jane")

      records = client.read(sync_config)

      expect(records).to be_an(Array)
      expect(records.length).to eq(2)

      multiwoven_message = records.first
      first_record = multiwoven_message.record
      expect(first_record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
      expect(first_record.data).to eq(id: 1, name: "John")
      expect(first_record.emitted_at).to be_an(Integer)
    end

    it "read failure" do
      allow(client).to receive(:create_connection).and_raise(StandardError.new("test error"))
      expect(client).to receive(:handle_exception).with(
        "DATABRICKS:READ:EXCEPTION",
        "error",
        an_instance_of(StandardError)
      )
      client.read(sync_config)
    end
  end
end
