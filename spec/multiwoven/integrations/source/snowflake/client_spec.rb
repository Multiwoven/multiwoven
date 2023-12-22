# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Snowflake::Client do
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
        "query": "SELECT * FROM CALL_CENTER LIMIT 1",
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
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(Sequel).to receive(:odbc).and_raise(Sequel::DatabaseConnectionError, "Connection failed")

        result = client.check_connection(sync_config[:source][:connection_specification])
        expect(result.status).to eq("failed")
        expect(result.message).to eq("Connection failed")
      end
    end
  end

  describe "#read" do
    it "reads records successfully" do
      allow(Sequel).to receive(:odbc).and_return(double("db").as_null_object)
      allow_any_instance_of(RSpec::Mocks::Double).to receive(:fetch).and_yield(id: 1, name: "John").and_yield(id: 2, name: "Jane")

      records = client.read(Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json))

      expect(records).to be_an(Array)
      expect(records.length).to eq(2)

      first_record = records.first
      expect(first_record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
      expect(first_record.data).to eq(id: 1, name: "John")
      expect(first_record.emitted_at).to be_an(Integer)
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

      streams = client.discover(sync_config[:source][:connection_specification])

      expect(streams).to be_an(Array)

      first_stream = streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq("TEST_TABLE")
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "ID" => { "type" => %w[integer null] } })
    end
  end
end
