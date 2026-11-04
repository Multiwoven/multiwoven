# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::SqlServer::Client do
  let(:client) { Multiwoven::Integrations::Source::SqlServer::Client.new }
  let(:sync_config) do
    {
      "source": {
        "name": "SqlServerSourceConnector",
        "type": "source",
        "connection_specification": {
          "data_type": "structured",
          "credentials": {
            "auth_type": "username/password",
            "username": ENV["SQLSERVER_USERNAME"],
            "password": ENV["SQLSERVER_PASSWORD"]
          },
          "host": "test.sqlserver.com",
          "port": "1433",
          "database": "test_database",
          "schema": "dbo"
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
        "name": "ExampleSqlServerModel",
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
      "destination_sync_mode": "upsert",
      "sync_id": "1"
    }
  end

  let(:vector_sync_config_json) do
    {
      source: {
        name: "SqlServer",
        type: "source",
        connection_specification: {
          host: "test.sqlserver.com",
          port: "1433",
          database: "test_database",
          schema: "dbo",
          credentials: {
            auth_type: "username/password",
            username: ENV["SQLSERVER_USERNAME"],
            password: ENV["SQLSERVER_PASSWORD"]
          }
        }
      },
      vector: "SELECT * FROM documents ORDER BY embedding",
      limit: 2
    }
  end

  let(:mssql_connection) { instance_double(TinyTds::Client) }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)
        allow(mssql_connection).to receive(:close).and_return(true)
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status

        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(TinyTds::Client).to receive(:new).and_raise(TinyTds::Error.new("Connection failed"))

        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  describe "#read" do
    context "when reading records from a SQL Server database" do
      it "reads records successfully" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)
        allow(mssql_connection).to receive(:execute).with("SELECT * FROM contacts").and_return(
          [
            { "column1" => "column1" },
            { "column2" => "column2" }
          ]
        )
        allow(mssql_connection).to receive(:close).and_return(true)
        records = client.read(s_config)
        expect(records).to be_an(Array)
        expect(records).not_to be_empty
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
      end

      it "reads records successfully for batched_query" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        s_config.limit = 100
        s_config.offset = 1
        allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)

        expected_query = "SELECT * FROM contacts ORDER BY [id] OFFSET 1 ROWS FETCH NEXT 100 ROWS ONLY"
        allow(mssql_connection).to receive(:execute).with(expected_query).and_return(
          [
            { "column1" => "column1" },
            { "column2" => "column2" }
          ]
        )
        allow(mssql_connection).to receive(:close).and_return(true)
        records = client.read(s_config)
        expect(records).to be_an(Array)
        expect(records).not_to be_empty
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
      end

      it "omits FETCH NEXT when offset is set without a limit" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        s_config.offset = 10
        allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)
        allow(mssql_connection).to receive(:close).and_return(true)

        expect(mssql_connection).to receive(:execute).with(
          "SELECT * FROM contacts ORDER BY [id] OFFSET 10 ROWS"
        ).and_return([])

        client.read(s_config)
      end

      it "appends primary_key as a tie-breaker when ORDER BY is present" do
        config = sync_config.deep_dup
        config[:model][:query] = "SELECT * FROM contacts ORDER BY created_at"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(config.to_json)
        s_config.limit = 10
        s_config.offset = 0
        allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)
        allow(mssql_connection).to receive(:close).and_return(true)

        expect(mssql_connection).to receive(:execute).with(
          "SELECT * FROM contacts ORDER BY created_at, [id] OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY"
        ).and_return([])

        client.read(s_config)
      end

      it "raises when paginating with an offset and without ORDER BY or primary_key" do
        config = sync_config.deep_dup
        config[:model][:primary_key] = ""
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(config.to_json)
        s_config.limit = 10
        s_config.offset = 5
        allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)
        allow(mssql_connection).to receive(:close).and_return(true)

        expect(client).to receive(:handle_exception).with(
          an_instance_of(ArgumentError), {
            context: "SQLSERVER:READ:EXCEPTION",
            type: "error",
            sync_id: "1",
            sync_run_id: nil
          }
        )
        client.read(s_config)
      end

      it "raises when limit is zero" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        s_config.limit = 0
        s_config.offset = 5
        allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)
        allow(mssql_connection).to receive(:close).and_return(true)

        expect(client).to receive(:handle_exception).with(
          an_instance_of(ArgumentError), {
            context: "SQLSERVER:READ:EXCEPTION",
            type: "error",
            sync_id: "1",
            sync_run_id: nil
          }
        )
        client.read(s_config)
      end

      it "reformats LIMIT/OFFSET clauses into OFFSET/FETCH NEXT" do
        config = sync_config.deep_dup
        config[:model][:query] = "SELECT * FROM contacts LIMIT 10 OFFSET 5;"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(config.to_json)
        allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)
        allow(mssql_connection).to receive(:close).and_return(true)

        expect(mssql_connection).to receive(:execute).with(
          "SELECT * FROM contacts ORDER BY [id] OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY"
        ).and_return([])

        client.read(s_config)
      end

      it "reformats offset-only queries without FETCH NEXT" do
        config = sync_config.deep_dup
        config[:model][:query] = "SELECT * FROM contacts OFFSET 5;"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(config.to_json)
        allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)
        allow(mssql_connection).to receive(:close).and_return(true)

        expect(mssql_connection).to receive(:execute).with(
          "SELECT * FROM contacts ORDER BY [id] OFFSET 5 ROWS"
        ).and_return([])

        client.read(s_config)
      end

      it "preserves semicolons inside SQL string literals" do
        config = sync_config.deep_dup
        config[:model][:query] = "SELECT 'a;b' AS value;"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(config.to_json)
        allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)
        allow(mssql_connection).to receive(:close).and_return(true)

        expect(mssql_connection).to receive(:execute).with("SELECT 'a;b' AS value").and_return([])

        client.read(s_config)
      end

      it "does not rewrite LIMIT/OFFSET that appear inside string literals" do
        config = sync_config.deep_dup
        config[:model][:query] = "SELECT 'LIMIT 1 OFFSET 2' AS value LIMIT 5;"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(config.to_json)
        allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)
        allow(mssql_connection).to receive(:close).and_return(true)

        expect(mssql_connection).to receive(:execute).with(
          "SELECT 'LIMIT 1 OFFSET 2' AS value ORDER BY [id] OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY"
        ).and_return([])

        client.read(s_config)
      end

      it "read records failure" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        s_config.sync_run_id = "2"
        allow(client).to receive(:create_connection).and_raise(StandardError.new("test error"))
        expect(client).to receive(:handle_exception).with(
          an_instance_of(StandardError), {
            context: "SQLSERVER:READ:EXCEPTION",
            type: "error",
            sync_id: "1",
            sync_run_id: "2"
          }
        )
        client.read(s_config)
      end
    end
  end

  describe "#search" do
    context "when vector searching records from a SQL Server database" do
      it "search records successfully" do
        s_config = Multiwoven::Integrations::Protocol::VectorConfig.from_json(vector_sync_config_json.to_json)
        allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)

        expected_query = "SELECT * FROM documents ORDER BY embedding OFFSET 0 ROWS FETCH NEXT 2 ROWS ONLY"
        allow(mssql_connection).to receive(:execute).with(expected_query).and_return(
          [
            { "id" => "1", "content" => "A", "score" => "0.2" },
            { "id" => "2", "content" => "B", "score" => "0.4" }
          ]
        )
        allow(mssql_connection).to receive(:close).and_return(true)
        records = client.search(s_config)
        expect(records).to be_an(Array)
        expect(records).not_to be_empty
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
      end

      it "search records failure" do
        s_config = Multiwoven::Integrations::Protocol::VectorConfig.from_json(vector_sync_config_json.to_json)
        allow(client).to receive(:create_connection).and_raise(StandardError.new("test error"))
        expect(client).to receive(:handle_exception).with(
          an_instance_of(StandardError), {
            context: "SQLSERVER:SEARCH:EXCEPTION",
            type: "error"
          }
        )
        client.search(s_config)
      end
    end
  end

  describe "#discover" do
    it "discovers schema successfully" do
      allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)

      discovery_query = "SELECT table_name, column_name, data_type, is_nullable
                 FROM information_schema.columns
                 WHERE table_schema = 'dbo'
                 ORDER BY table_name, ordinal_position;"
      allow(mssql_connection).to receive(:execute).with(discovery_query).and_return(
        [
          {
            "TABLE_NAME" => "combined_users", "COLUMN_NAME" => "city", "DATA_TYPE" => "varchar", "IS_NULLABLE" => "YES"
          }
        ]
      )
      allow(mssql_connection).to receive(:close).and_return(true)
      message = client.discover(sync_config[:source][:connection_specification])

      expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
      first_stream = message.catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq("combined_users")
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "city" => { "type" => %w[string null] } })
    end

    it "defaults schema to dbo when schema is blank" do
      config = sync_config[:source][:connection_specification].deep_dup
      config[:schema] = ""
      allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)
      allow(mssql_connection).to receive(:close).and_return(true)

      expect(mssql_connection).to receive(:execute).with(
        a_string_including("WHERE table_schema = 'dbo'")
      ).and_return([])

      client.discover(config)
    end

    it "escapes single quotes in schema names" do
      config = sync_config[:source][:connection_specification].deep_dup
      config[:schema] = "dbo'; DROP TABLE users; --"
      allow(TinyTds::Client).to receive(:new).and_return(mssql_connection)
      allow(mssql_connection).to receive(:close).and_return(true)

      expect(mssql_connection).to receive(:execute).with(
        a_string_including("WHERE table_schema = 'dbo''; DROP TABLE users; --'")
      ).and_return([])

      client.discover(config)
    end

    it "discover schema failure" do
      allow(client).to receive(:create_connection).and_raise(StandardError.new("test error"))
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError), {
          context: "SQLSERVER:DISCOVER:EXCEPTION",
          type: "error"
        }
      )
      client.discover(sync_config[:source][:connection_specification])
    end
  end

  describe "#query" do
    it "converts query_source LIMIT clauses to TOP without requiring ORDER BY" do
      allow(mssql_connection).to receive(:execute).with("SELECT TOP 50 * FROM customers").and_return(
        [{ "id" => 1 }]
      )

      records = client.send(:query, mssql_connection, "SELECT * FROM customers LIMIT 50")
      expect(records).to be_an(Array)
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "preserves DISTINCT when converting LIMIT to TOP" do
      allow(mssql_connection).to receive(:execute).with(
        "SELECT DISTINCT TOP 25 * FROM customers"
      ).and_return([])

      client.send(:query, mssql_connection, "SELECT DISTINCT * FROM customers LIMIT 25")
    end

    it "preserves ALL when converting LIMIT to TOP" do
      allow(mssql_connection).to receive(:execute).with(
        "SELECT ALL TOP 10 * FROM customers"
      ).and_return([])

      client.send(:query, mssql_connection, "SELECT ALL * FROM customers LIMIT 10")
    end

    it "raises when the query already contains TOP" do
      expect do
        client.send(:query, mssql_connection, "SELECT TOP 5 * FROM customers LIMIT 10")
      end.to raise_error(ArgumentError, /already contains TOP/i)
    end

    it "raises when the query already contains DISTINCT TOP" do
      expect do
        client.send(:query, mssql_connection, "SELECT DISTINCT TOP 5 * FROM customers LIMIT 10")
      end.to raise_error(ArgumentError, /already contains TOP/i)
    end

    it "raises for LIMIT 0 instead of emitting FETCH NEXT 0" do
      client.instance_variable_set(:@pagination_primary_key, "id")

      expect do
        client.send(:query, mssql_connection, "SELECT * FROM customers LIMIT 0")
      end.to raise_error(ArgumentError, "Limit must be at least 1")
    ensure
      client.instance_variable_set(:@pagination_primary_key, nil)
    end

    it "strips multiple trailing semicolons without altering the query body" do
      allow(mssql_connection).to receive(:execute).with("SELECT * FROM customers").and_return([])

      client.send(:query, mssql_connection, "SELECT * FROM customers;;;;")
    end

    it "strips trailing semicolons after whitespace" do
      allow(mssql_connection).to receive(:execute).with("SELECT * FROM customers").and_return([])

      client.send(:query, mssql_connection, "SELECT * FROM customers;;;  ")
    end

    it "preserves semicolons inside literals while stripping repeated terminators" do
      allow(mssql_connection).to receive(:execute).with("SELECT 'a;b;;c' AS value").and_return([])

      client.send(:query, mssql_connection, "SELECT 'a;b;;c' AS value;;;")
    end

    it "converts LIMIT with a trailing terminator via query" do
      allow(mssql_connection).to receive(:execute).with("SELECT TOP 10 * FROM customers").and_return([])

      client.send(:query, mssql_connection, "SELECT * FROM customers LIMIT 10;")
    end
  end

  describe "#create_connection" do
    let(:connection_config) do
      {
        credentials: {
          auth_type: "username/password",
          username: "sql_user",
          password: "sql_password"
        },
        host: "test.sqlserver.com",
        port: "1433",
        database: "test_database",
        schema: "dbo"
      }
    end

    it "defaults azure to false when the field is omitted" do
      expect(TinyTds::Client).to receive(:new).with(
        hash_including(azure: false, port: "1433", database: "test_database")
      ).and_return(mssql_connection)

      client.send(:create_connection, connection_config)
    end

    it "passes azure true through to TinyTds" do
      expect(TinyTds::Client).to receive(:new).with(
        hash_including(azure: true)
      ).and_return(mssql_connection)

      client.send(:create_connection, connection_config.merge(azure: true))
    end

    it "defaults port to 1433 when port is blank" do
      expect(TinyTds::Client).to receive(:new).with(
        hash_including(port: 1433)
      ).and_return(mssql_connection)

      client.send(:create_connection, connection_config.merge(port: ""))
    end
  end

  describe "#strip_trailing_terminator" do
    it "removes only trailing statement terminators" do
      expect(client.send(:strip_trailing_terminator, "SELECT 1;")).to eq("SELECT 1")
      expect(client.send(:strip_trailing_terminator, "SELECT 1;;;")).to eq("SELECT 1")
      expect(client.send(:strip_trailing_terminator, "SELECT 1; \t")).to eq("SELECT 1")
    end

    it "does not remove semicolons inside string literals" do
      expect(client.send(:strip_trailing_terminator, "SELECT ';;;' AS v;")).to eq("SELECT ';;;' AS v")
      expect(client.send(:strip_trailing_terminator, "SELECT N'a;b' AS v;;")).to eq("SELECT N'a;b' AS v")
    end

    it "handles many repeated trailing semicolons without regex backtracking" do
      query = "SELECT 1#{";" * 10_000}"
      expect(client.send(:strip_trailing_terminator, query)).to eq("SELECT 1")
    end
  end

  describe "#meta_data" do
    it "returns the correct meta data" do
      meta_data = client.send(:meta_data)
      meta_name = client.class.to_s.split("::")[-2]
      expect(meta_data).to be_a(Hash)
      expect(meta_data[:data][:name]).to eq(meta_name)
      expect(meta_data[:data][:connector_type]).to eq("source")
      expect(meta_data[:data][:icon]).to eq("https://res.cloudinary.com/dspflukeu/image/upload/v1790358609/Multiwoven/connectors/sql_server/icon.svg")
    end
  end

  describe "method definition" do
    it "defines a private #query method" do
      expect(described_class.private_instance_methods).to include(:query)
    end
  end
end
