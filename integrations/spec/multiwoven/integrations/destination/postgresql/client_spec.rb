# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Postgresql::Client do
  let(:client) { Multiwoven::Integrations::Destination::Postgresql::Client.new }
  let(:sync_config) do
    {
      "source": {
        "name": "PostgresqlSourceConnector",
        "type": "source",
        "connection_specification": {
          "credentials": {
            "auth_type": "username/password",
            "username": ENV["POSTGRESQL_USERNAME"],
            "password": ENV["POSTGRESQL_PASSWORD"]
          },
          "host": "test.pg.com",
          "port": "8080",
          "database": "test_database",
          "schema": "test_schema"
        }
      },
      "destination": {
        "name": "Postgresql",
        "type": "destination",
        "connection_specification": {
          "credentials": {
            "auth_type": "username/password",
            "username": ENV["POSTGRESQL_USERNAME"],
            "password": ENV["POSTGRESQL_PASSWORD"]
          },
          "host": "test.pg.com",
          "port": "8080",
          "database": "test_database",
          "schema": "test_schema"
        }
      },
      "model": {
        "name": "ExamplePostgresqlModel",
        "query": "SELECT * FROM contacts;",
        "query_type": "raw_sql",
        "primary_key": "id"
      },
      "stream": {
        "name": "users", "action": "create",
        "json_schema": { "user_id": "string", "email": "string", "location": "string" },
        "supported_sync_modes": %w[full_refresh incremental]
      },
      "sync_mode": "full_refresh",
      "cursor_field": "timestamp",
      "destination_sync_mode": "upsert",
      "sync_id": "1"
    }
  end

  let(:pg_connection) { instance_double(PG::Connection) }
  let(:pg_result) { instance_double(PG::Result) }

  let(:records) do
    [
      Multiwoven::Integrations::Protocol::RecordMessage.new(
        data: {
          email: "user1@example.com",
          location: "New York",
          user_id: 1
        },
        emitted_at: Time.now.to_i
      ),
      Multiwoven::Integrations::Protocol::RecordMessage.new(
        data: {
          email: "user2@example.com",
          location: "San Francisco",
          user_id: 2
        },
        emitted_at: Time.now.to_i
      )
    ]
  end

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

  # write specs

  describe "#write" do
    context "success" do
      it "write records successfully" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        s_config.sync_run_id = "33"
        allow(PG).to receive(:connect).and_return(pg_connection)

        allow(pg_connection).to receive(:exec).and_return(true)

        tracking = subject.write(s_config, [records.first.data.transform_keys(&:to_s)]).tracking
        expect(tracking.success).to eql(1)
        log_message = tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("info")

        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end

      it "write records successfully on update record action destination_update" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        s_config.sync_run_id = "33"
        allow(PG).to receive(:connect).and_return(pg_connection)

        allow(pg_connection).to receive(:exec).and_return(true)

        tracking = subject.write(s_config, [records.first.data.transform_keys(&:to_s)], "destination_update").tracking
        expect(tracking.success).to eql(1)
        expect(tracking.logs.count).to eql(1)
        log_message = tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("info")

        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end
    end

    context "failure" do
      it "handle record write failures" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        s_config.sync_run_id = "34"

        allow(PG).to receive(:connect).and_return(pg_connection)

        allow(pg_connection).to receive(:exec).and_raise(StandardError.new("test error"))

        tracking = subject.write(s_config, [records.first.data.transform_keys(&:to_s)]).tracking
        expect(tracking.failed).to eql(1)
        expect(tracking.logs.count).to eql(1)
        log_message = tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("error")
        expect(log_message.message).to include("request")
        expect(log_message.message).to include("\"response\":\"test error\"")
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
        an_instance_of(StandardError), {
          context: "POSTGRESQL:DISCOVER:EXCEPTION",
          type: "error"
        }
      )
      client.discover(sync_config[:source][:connection_specification])
    end
  end

  describe "#meta_data" do
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
