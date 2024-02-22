# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Snowflake::Client do # rubocop:disable Metrics/BlockLength
  let(:client) { Multiwoven::Integrations::Source::Snowflake::Client.new }
  # TODO: Move to test helpers
  let(:sync_config) do
    {
      "source": {
        "name": "SourceConnectorName",
        "type": "source",
        "connection_specification": {
          "credentials": {
            "auth_type": "username/password",
            "username": "SUBINTP",
            "password": "cGK6cmNPQX4Ao8"
          },
          "host": "PZMMZYT-wi50801.snowflakecomputing.com",
          "role": "",
          "warehouse": "COMPUTE_WH",
          "database": "SNOWFLAKE_SAMPLE_DATA",
          "schema": "TPCDS_SF10TCL",
          "jdbc_url_params": "key1=value1&key2=value2"
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
        "query": "SELECT * FROM CALL_CENTER",
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
  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(Sequel).to receive(:odbc).and_return(true)

        result = client.check_connection(sync_config[:source][:connection_specification])
        expect(result.type).to eq("connection_status")

        connection_status = result.connection_status
        expect(connection_status.status).to eq("succeeded")
        expect(connection_status.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(Sequel).to receive(:odbc).and_raise(Sequel::DatabaseConnectionError, "Connection failed")

        result = client.check_connection(sync_config[:source][:connection_specification])
        expect(result.type).to eq("connection_status")

        connection_status = result.connection_status
        expect(connection_status.status).to eq("failed")
        expect(connection_status.message).to eq("Connection failed")
      end
    end
  end

  describe "#read" do
    let(:s_config) { Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json) }
    it "reads records successfully" do
      allow(Sequel).to receive(:odbc).and_return(double("db").as_null_object)

      allow_any_instance_of(RSpec::Mocks::Double).to receive(:fetch).with(s_config.model.query).and_yield(id: 1, name: "John").and_yield(id: 2, name: "Jane")

      records = client.read(s_config)

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

      s_config.limit = "10"
      s_config.offset = "1"

      batched_query = client.send(:batched_query, s_config.model.query, s_config.limit, s_config.offset)

      allow_any_instance_of(RSpec::Mocks::Double).to receive(:fetch).with(batched_query).and_yield(id: 1, name: "John").and_yield(id: 2, name: "Jane")

      records = client.read(s_config)

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
        "SNOWFLAKE:READ:EXCEPTION",
        "error",
        an_instance_of(StandardError)
      )
      client.read(Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json))
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
        "SNOWFLAKE:DISCOVER:EXCEPTION",
        "error",
        an_instance_of(StandardError)
      )
      client.discover(sync_config[:source][:connection_specification])
    end
  end

  describe "method definition" do
    it "defines a private #query method" do
      expect(described_class.private_instance_methods).to include(:query)
    end
  end
end
