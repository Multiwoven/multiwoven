# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::GoogleCloudStorage::Client do
  let(:client) { Multiwoven::Integrations::Source::GoogleCloudStorage::Client.new }
  let(:storage_client) { instance_double(Google::Cloud::Storage::Project) }
  let(:bucket) { instance_double(Google::Cloud::Storage::Bucket) }
  let(:duckdb_conn) { instance_double(DuckDB::Connection) }
  let(:query_result) { instance_double("DuckDB::Result") }

  let(:connection_config) do
    {
      "project_id" => "test-project",
      "client_email" => "test@example.com",
      "private_key" => "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n",
      "bucket" => "test-bucket",
      "path" => "test-path",
      "file_type" => "csv"
    }
  end

  # Create a hash representation of the sync config
  let(:sync_config_hash) do
    {
      "source" => {
        "name" => "GoogleCloudStorage",
        "type" => "source",
        "connection_specification" => connection_config
      },
      "destination" => {
        "name" => "Sample Destination Connector",
        "type" => "destination",
        "connection_specification" => {
          "example_destination_key" => "example_destination_value"
        }
      },
      "model" => {
        "name" => "GCS File Content Query",
        "query" => "SELECT * FROM gcs_data",
        "query_type" => "raw_sql",
        "primary_key" => "id"
      },
      "stream" => {
        "name" => "example_stream",
        "action" => "create",
        "json_schema" => { "field1" => "type1" },
        "supported_sync_modes" => %w[full_refresh incremental],
        "source_defined_cursor" => true,
        "default_cursor_field" => ["field1"],
        "source_defined_primary_key" => [["field1"], ["field2"]],
        "namespace" => "exampleNamespace"
      },
      "sync_id" => "1",
      "sync_mode" => "incremental",
      "cursor_field" => "",
      "destination_sync_mode" => "upsert"
    }
  end

  # Convert the hash to a SyncConfig object
  let(:sync_config) do
    Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_hash.to_json)
  end

  let(:file_content) { "id,name\n1,Test User\n2,Another User" }
  let(:file_double) { instance_double(Google::Cloud::Storage::File) }
  let(:files_array) { [file_double] }

  before do
    # Common setup for file_double
    allow(file_double).to receive(:name).and_return("test-path/data.csv")
    allow(file_double).to receive(:download).and_return(file_content)
    allow(file_double).to receive(:download).with(any_args).and_return(nil)

    # Initialize client with connection config before each test
    client.send(:initialize_client, connection_config)
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        # Setup mocks
        allow(client).to receive(:create_storage_client).and_return(storage_client)
        allow(storage_client).to receive(:bucket).with("test-bucket").and_return(bucket)
        allow(bucket).to receive(:exists?).and_return(true)
        allow(bucket).to receive(:nil?).and_return(false)
        allow(client).to receive(:list_files).with(bucket).and_return(files_array)

        # Call the method
        message = client.check_connection(connection_config)
        result = message.connection_status

        # Assertions
        expect(result.status).to eq("succeeded")
        expect(result.message).to include("Successfully connected")
      end
    end

    context "when the bucket doesn't exist" do
      it "returns a failed connection status" do
        # Setup mocks
        allow(client).to receive(:create_storage_client).and_return(storage_client)
        allow(storage_client).to receive(:bucket).with("test-bucket").and_return(bucket)
        allow(bucket).to receive(:exists?).and_return(false)

        # Call the method
        message = client.check_connection(connection_config)
        result = message.connection_status

        # Assertions
        expect(result.status).to eq("failed")
        expect(result.message).to include("Bucket")
        expect(result.message).to include("not found")
      end
    end

    context "when no files are found" do
      it "returns a failed connection status" do
        # Setup mocks
        allow(client).to receive(:create_storage_client).and_return(storage_client)
        allow(storage_client).to receive(:bucket).with("test-bucket").and_return(bucket)
        allow(bucket).to receive(:exists?).and_return(true)
        allow(bucket).to receive(:nil?).and_return(false)
        allow(client).to receive(:list_files).with(bucket).and_return([])

        # Call the method
        message = client.check_connection(connection_config)
        result = message.connection_status

        # Assertions
        expect(result.status).to eq("failed")
        expect(result.message).to include("No csv files found")
      end
    end

    context "when an exception occurs" do
      it "returns a failed connection status with error message" do
        # Setup mocks to raise an exception
        allow(client).to receive(:create_storage_client).and_raise(StandardError, "Connection failed")

        # Call the method
        message = client.check_connection(connection_config)
        result = message.connection_status

        # Assertions
        expect(result.status).to eq("failed")
        expect(result.message).to include("Failed to connect")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  describe "#discover" do
    context "when files are found" do
      it "discovers schema from CSV files" do
        # Setup mocks
        allow(client).to receive(:create_storage_client).and_return(storage_client)
        allow(storage_client).to receive(:bucket).with("test-bucket").and_return(bucket)
        allow(client).to receive(:list_files).with(bucket).and_return(files_array)

        # Mock CSV parsing
        csv_double = double("CSV")
        csv_headers = %w[id name]
        allow(CSV).to receive(:parse).and_return(csv_double)
        allow(csv_double).to receive(:headers).and_return(csv_headers)

        # Call the method
        message = client.discover(connection_config)
        catalog = message.catalog

        # Assertions
        expect(catalog.streams).not_to be_empty
        expect(catalog.streams.first.name).to eq("test-bucket_csv_files")
        expect(catalog.streams.first.json_schema["properties"]).to include("id", "name")
      end
    end

    context "when no files are found" do
      it "returns an empty catalog" do
        # Setup mocks
        allow(client).to receive(:create_storage_client).and_return(storage_client)
        allow(storage_client).to receive(:bucket).with("test-bucket").and_return(bucket)
        allow(client).to receive(:list_files).with(bucket).and_return([])

        # Call the method
        message = client.discover(connection_config)
        catalog = message.catalog

        # Assertions
        expect(catalog.streams).to be_empty
      end
    end

    context "when an exception occurs" do
      it "handles discover failure" do
        # Setup mocks to raise an exception
        allow(client).to receive(:create_storage_client).and_raise(StandardError, "test error")
        expect(client).to receive(:handle_exception).with(
          an_instance_of(StandardError), {
            context: "GOOGLECLOUDSTORAGE:DISCOVER:EXCEPTION",
            type: "error"
          }
        )

        # Call the method
        client.discover(connection_config)
      end
    end
  end

  describe "#read" do
    context "when using SQL query" do
      it "processes the query and returns records" do
        # Setup mocks
        allow(client).to receive(:create_connection).and_return(duckdb_conn)

        # Setup expected results from the query
        allow(client).to receive(:query).with(duckdb_conn, "SELECT * FROM gcs_data").and_return(
          [
            Multiwoven::Integrations::Protocol::RecordMessage.new(
              data: { "id" => "1", "name" => "Test User" },
              emitted_at: Time.now.to_i
            ).to_multiwoven_message,
            Multiwoven::Integrations::Protocol::RecordMessage.new(
              data: { "id" => "2", "name" => "Another User" },
              emitted_at: Time.now.to_i
            ).to_multiwoven_message
          ]
        )

        # Call the method
        records = client.read(sync_config)

        # Assertions
        expect(records).to be_an(Array)
        expect(records.size).to eq(2)
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(records.first.record.data).to eq({ "id" => "1", "name" => "Test User" })
        expect(records.last.record.data).to eq({ "id" => "2", "name" => "Another User" })
      end
    end

    context "when using batched query" do
      it "adds limit and offset to the query" do
        # Setup sync_config with limit and offset
        sync_config_with_limit = sync_config.dup
        sync_config_with_limit.limit = 10
        sync_config_with_limit.offset = 5

        # Setup mocks
        allow(client).to receive(:create_connection).and_return(duckdb_conn)

        # Setup expected batched query and results
        batched_query = "SELECT * FROM gcs_data LIMIT 10 OFFSET 5"
        allow(client).to receive(:query).with(duckdb_conn, batched_query).and_return(
          [
            Multiwoven::Integrations::Protocol::RecordMessage.new(
              data: { "id" => "6", "name" => "User 6" },
              emitted_at: Time.now.to_i
            ).to_multiwoven_message
          ]
        )

        # Call the method
        records = client.read(sync_config_with_limit)

        # Assertions
        expect(records).to be_an(Array)
        expect(records.size).to eq(1)
        expect(records.first.record.data).to eq({ "id" => "6", "name" => "User 6" })
      end
    end

    context "when no query is provided" do
      it "reads records directly from GCS files" do
        # Create a new sync_config with empty query
        sync_config_hash_no_query = sync_config_hash.dup
        sync_config_hash_no_query["model"] = {
          "name" => "GCS File Content Query",
          "query" => "",
          "query_type" => "raw_sql",
          "primary_key" => "id"
        }

        # Convert to SyncConfig object
        sync_config_no_query = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_hash_no_query.to_json)

        # Setup mocks for reading files directly
        allow(client).to receive(:create_storage_client).and_return(storage_client)
        allow(storage_client).to receive(:bucket).with("test-bucket").and_return(bucket)
        allow(client).to receive(:list_files).with(bucket).and_return(files_array)

        # Mock CSV parsing with real CSV data
        csv_rows = [
          { "id" => "1", "name" => "Test User" },
          { "id" => "2", "name" => "Another User" }
        ]
        csv_mock = csv_rows.map { |row| double(to_h: row) }
        allow(CSV).to receive(:parse).with(anything, headers: true).and_return(csv_mock)

        # Call the method
        records = client.read(sync_config_no_query)

        # Assertions
        expect(records).to be_an(Array)
        expect(records.size).to eq(2)
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(records.first.record.data).to include("id" => "1", "name" => "Test User")
      end
    end

    context "when an exception occurs" do
      it "handles read failure" do
        # Setup sync_config with sync_run_id
        sync_config_with_run_id = sync_config.dup
        sync_config_with_run_id.sync_run_id = "2"

        # Setup mocks to raise an exception
        allow(client).to receive(:create_connection).and_raise(StandardError, "test error")
        expect(client).to receive(:handle_exception).with(
          an_instance_of(StandardError), {
            context: "GOOGLECLOUDSTORAGE:READ:EXCEPTION",
            type: "error",
            sync_id: "1",
            sync_run_id: "2"
          }
        )

        # Call the method
        client.read(sync_config_with_run_id)
      end
    end
  end

  describe "#create_connection" do
    it "initializes client and returns a DuckDB connection" do
      # Setup mocks
      duckdb_database = instance_double(DuckDB::Database)
      allow(DuckDB::Database).to receive(:open).and_return(duckdb_database)
      allow(duckdb_database).to receive(:connect).and_return(duckdb_conn)

      # Call the method
      result = client.create_connection(connection_config)

      # Assertions
      expect(result).to eq(duckdb_conn)
    end
  end

  describe "#query" do
    it "executes a query and returns formatted records" do
      # Setup mocks
      query_results = [{ "id" => "1", "name" => "Test User" }]
      allow(client).to receive(:results).with(duckdb_conn, "SELECT * FROM gcs_data").and_return(query_results)

      # Call the method
      records = client.query(duckdb_conn, "SELECT * FROM gcs_data")

      # Assertions
      expect(records).to be_an(Array)
      expect(records.size).to eq(1)
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
      expect(records.first.record.data).to eq({ "id" => "1", "name" => "Test User" })
    end
  end

  describe "#results" do
    before do
      # Set up instance variables directly
      client.instance_variable_set(:@bucket, "test-bucket")
      client.instance_variable_set(:@file_type, "csv")

      allow(client).to receive(:create_storage_client).and_return(storage_client)
      allow(storage_client).to receive(:bucket).with("test-bucket").and_return(bucket)
      allow(client).to receive(:list_files).with(bucket).and_return(files_array)

      # Mock Dir and FileUtils
      allow(Dir).to receive(:mktmpdir).and_return("/tmp/gcs_query")
      allow(File).to receive(:join).and_return("/tmp/gcs_query/data.csv")
      allow(File).to receive(:basename).and_return("data.csv")
      allow(Dir).to receive(:exist?).and_return(true)
      allow(FileUtils).to receive(:remove_entry)

      # Mock DuckDB connection
      allow(duckdb_conn).to receive(:execute)
      allow(duckdb_conn).to receive(:query).and_return(query_result)
      allow(query_result).to receive(:columns).and_return([
                                                            double(name: "id"),
                                                            double(name: "name")
                                                          ])
      allow(query_result).to receive(:each).and_yield(["1", "Test User"])
    end

    it "executes a query against downloaded CSV file and returns results" do
      # Call the private method
      results = client.send(:results, duckdb_conn, "SELECT * FROM gcs_data")

      # Assertions
      expect(results).to be_an(Array)
      expect(results.size).to eq(1)
      expect(results.first).to eq({ "id" => "1", "name" => "Test User" })
    end

    it "handles empty file list" do
      # Setup mocks for empty file list
      allow(client).to receive(:list_files).with(bucket).and_return([])

      # Call the private method
      results = client.send(:results, duckdb_conn, "SELECT * FROM gcs_data")

      # Assertions
      expect(results).to eq([])
    end

    it "handles query exceptions" do
      # Setup mocks to raise an exception
      allow(duckdb_conn).to receive(:execute).and_raise(StandardError, "Query failed")

      # Allow handle_exception to accept any StandardError
      expect(client).to receive(:handle_exception) do |exception, options|
        expect(exception).to be_a(StandardError)
        expect(options).to eq({
                                context: "GOOGLECLOUDSTORAGE:QUERY:EXCEPTION",
                                type: "error"
                              })
        # Return an empty array to satisfy the test
        []
      end

      # Call the private method
      result = client.send(:results, duckdb_conn, "SELECT * FROM gcs_data")

      # Assertions
      expect(result).to eq([])
    end
  end

  describe "#batched_query" do
    it "adds LIMIT and OFFSET to a query" do
      # Call the private method
      result = client.send(:batched_query, "SELECT * FROM gcs_data", 10, 5)

      # Assertions
      expect(result).to eq("SELECT * FROM gcs_data LIMIT 10 OFFSET 5")
    end

    it "removes trailing semicolon before adding LIMIT and OFFSET" do
      # Call the private method
      result = client.send(:batched_query, "SELECT * FROM gcs_data;", 10, 5)

      # Assertions
      expect(result).to eq("SELECT * FROM gcs_data LIMIT 10 OFFSET 5")
    end
  end

  describe "#create_storage_client" do
    it "creates a Google Cloud Storage client with proper credentials" do
      # Set up instance variables directly
      client.instance_variable_set(:@project_id, "test-project")
      client.instance_variable_set(:@client_email, "test@example.com")
      client.instance_variable_set(:@private_key, "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n")

      # Setup mocks
      allow(Google::Cloud::Storage).to receive(:new).and_return(storage_client)

      # Call the private method
      result = client.send(:create_storage_client)

      # Assertions
      expect(result).to eq(storage_client)
      expect(Google::Cloud::Storage).to have_received(:new).with(
        project_id: "test-project",
        credentials: {
          type: "service_account",
          project_id: "test-project",
          private_key: "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n",
          client_email: "test@example.com"
        }
      )
    end
  end

  describe "#initialize_client" do
    it "sets instance variables from connection config" do
      # Call the private method with a fresh client to avoid interference from before block
      fresh_client = Multiwoven::Integrations::Source::GoogleCloudStorage::Client.new
      fresh_client.send(:initialize_client, connection_config)

      # Assertions
      expect(fresh_client.instance_variable_get(:@project_id)).to eq("test-project")
      expect(fresh_client.instance_variable_get(:@client_email)).to eq("test@example.com")
      expect(fresh_client.instance_variable_get(:@private_key)).to eq("-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n")
      expect(fresh_client.instance_variable_get(:@bucket)).to eq("test-bucket")
      expect(fresh_client.instance_variable_get(:@path)).to eq("test-path")
      expect(fresh_client.instance_variable_get(:@file_type)).to eq("csv")
    end
  end

  describe "#bucket" do
    it "gets the bucket using the cached storage client" do
      # Setup mocks
      allow(client).to receive(:storage_client).and_return(storage_client)
      allow(storage_client).to receive(:bucket).with("test-bucket").and_return(bucket)

      # Call the private method
      result = client.send(:bucket)

      # Assertions
      expect(result).to eq(bucket)
    end
  end

  describe "#path_prefix" do
    it "formats the path prefix correctly when it starts with a slash" do
      # Setup
      client.instance_variable_set(:@path, "/test-path")

      # Call the private method
      result = client.send(:path_prefix)

      # Assertions
      expect(result).to eq("test-path")
    end

    it "keeps the path prefix as is when it doesn't start with a slash" do
      # Setup
      client.instance_variable_set(:@path, "test-path")

      # Call the private method
      result = client.send(:path_prefix)

      # Assertions
      expect(result).to eq("test-path")
    end
  end

  describe "#list_files" do
    it "lists files with the correct prefix and filters by file type" do
      # Setup mocks
      allow(bucket).to receive(:files).with(prefix: "test-path").and_return(files_array)

      # Setup client instance variables
      client.instance_variable_set(:@path, "test-path")
      client.instance_variable_set(:@file_type, "csv")

      # Call the private method
      result = client.send(:list_files, bucket)

      # Assertions
      expect(result).to eq(files_array)
    end

    it "handles nil result from bucket.files" do
      # Setup mocks
      allow(bucket).to receive(:files).with(prefix: "test-path").and_return(nil)

      # Setup client instance variables
      client.instance_variable_set(:@path, "test-path")
      client.instance_variable_set(:@file_type, "csv")

      # Call the private method
      result = client.send(:list_files, bucket)

      # Assertions
      expect(result).to eq([])
    end
  end

  describe "#schema_from_file" do
    it "creates a schema from CSV file content" do
      # Setup
      client.instance_variable_set(:@file_type, "csv")

      # Mock CSV data
      file_content = "id,name\n1,Test User"
      csv_headers = %w[id name]
      csv_data = [["1", "Test User"]]
      csv = double("CSV")
      allow(CSV).to receive(:parse).with(file_content, headers: true).and_return(csv)
      allow(csv).to receive(:headers).and_return(csv_headers)
      allow(csv).to receive(:first).and_return(csv_data)

      # Call the private method
      result = client.send(:schema_from_file, file_content)

      # Assertions
      expect(result).to be_a(Hash)
      expect(result["type"]).to eq("object")
      expect(result["properties"]).to include("id", "name")
      expect(result["properties"]["id"]).to eq({ "type" => "string" })
      expect(result["properties"]["name"]).to eq({ "type" => "string" })
    end

    it "creates a placeholder schema for parquet files" do
      # Setup
      client.instance_variable_set(:@file_type, "parquet")
      file_content = "mock parquet content"

      # Call the private method
      result = client.send(:schema_from_file, file_content)

      # Assertions
      expect(result).to be_a(Hash)
      expect(result["type"]).to eq("object")
      expect(result["properties"]).to include("data")
      expect(result["properties"]["data"]).to eq({ "type" => "object" })
    end

    it "creates an empty schema for unknown file types" do
      # Setup
      client.instance_variable_set(:@file_type, "unknown")
      file_content = "mock unknown content"

      # Call the private method
      result = client.send(:schema_from_file, file_content)

      # Assertions
      expect(result).to be_a(Hash)
      expect(result["type"]).to eq("object")
      expect(result["properties"]).to eq({})
    end
  end
end
