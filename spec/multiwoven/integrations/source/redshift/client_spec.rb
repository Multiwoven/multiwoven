# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Redshift::Client do # rubocop:disable Metrics/BlockLength
  let(:client) { Multiwoven::Integrations::Source::Redshift::Client.new }
  let(:sync_config) do
    {
      "source": {
        "name": "RedshiftSourceConnector",
        "type": "source",
        "connection_specification": {
          "credentials": {
            "auth_type": "username/password",
            "username": ENV["REDSHIFT_USERNAME"],
            "password": ENV["REDSHIFT_PASSWORD"]
          },
          "host": "test.pg.com",
          "port": "8080",
          "database": "test_database",
          "schema": "test_schema"
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
        "name": "ExampleRedshiftModel",
        "query": "SELECT * FROM contacts;",
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

  let(:pg_connection) { instance_double(PG::Connection) }
  let(:pg_result) { instance_double(PG::Result) }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(Sequel).to receive(:postgres).and_return(true)
        allow(PG).to receive(:connect).and_return(pg_connection)
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status

        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(PG).to receive(:connect).and_raise(PG::Error.new("Connection failed"))

        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  # read and #discover tests for Redshift
  describe "#read" do
    context "when reading records from a real Redshift database" do
      it "reads records successfully" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        allow(PG).to receive(:connect).and_return(pg_connection)

        allow(pg_connection).to receive(:exec).with(s_config.model.query).and_return(
          [
            Multiwoven::Integrations::Protocol::RecordMessage.new(
              data: { column1: "column1" }, emitted_at: Time.now.to_i
            ).to_multiwoven_message,
            Multiwoven::Integrations::Protocol::RecordMessage.new(
              data: { column2: "column2" }, emitted_at: Time.now.to_i
            ).to_multiwoven_message
          ]
        )
        allow(pg_connection).to receive(:close).and_return(true)
        records = client.read(s_config)
        expect(records).to be_an(Array)
        expect(records).not_to be_empty
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
      end

      it "reads records successfully for batched_query" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        s_config.limit = 100
        s_config.offset = 1
        allow(PG).to receive(:connect).and_return(pg_connection)

        batched_query = client.send(:batched_query, s_config.model.query, s_config.limit, s_config.offset)

        allow(pg_connection).to receive(:exec).with(batched_query).and_return(
          [
            Multiwoven::Integrations::Protocol::RecordMessage.new(
              data: { column1: "column1" }, emitted_at: Time.now.to_i
            ).to_multiwoven_message,
            Multiwoven::Integrations::Protocol::RecordMessage.new(
              data: { column2: "column2" }, emitted_at: Time.now.to_i
            ).to_multiwoven_message
          ]
        )
        allow(pg_connection).to receive(:close).and_return(true)
        records = client.read(s_config)
        expect(records).to be_an(Array)
        expect(records).not_to be_empty
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
      end

      it "read records failure" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        allow(client).to receive(:create_connection).and_raise(StandardError.new("test error"))
        expect(client).to receive(:handle_exception).with(
          "REDSHIFT:READ:EXCEPTION",
          "error",
          an_instance_of(StandardError)
        )
        client.read(s_config)
      end
    end
  end

  describe "#discover" do
    it "discovers schema successfully" do
      allow(PG).to receive(:connect).and_return(pg_connection)
      discovery_query = "SELECT table_name, column_name, data_type, is_nullable\n" \
                      "                 FROM information_schema.columns\n" \
                      "                 WHERE table_schema = 'test_schema' AND table_catalog = 'test_database'\n" \
                      "                 ORDER BY table_name, ordinal_position;"
      allow(pg_connection).to receive(:exec).with(discovery_query).and_return(
        [
          {
            "table_name" => "combined_users", "column_name" => "city", "data_type" => "varchar", "is_nullable" => "YES"
          }
        ]
      )
      allow(pg_connection).to receive(:close).and_return(true)
      message = client.discover(sync_config[:source][:connection_specification])

      expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
      first_stream = message.catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq("combined_users")
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "city" => { "type" => %w[string null] } })
    end

    it "discover schema failure" do
      allow(client).to receive(:create_connection).and_raise(StandardError.new("test error"))
      expect(client).to receive(:handle_exception).with(
        "REDSHIFT:DISCOVER:EXCEPTION",
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
      expect(client.send(:meta_data)["data"]["name"]).to eq(meta_name)
    end
  end
end
