# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Audience::Client do
  let(:client) { Multiwoven::Integrations::Source::Audience::Client.new }
  let(:storage_client) { instance_double(Google::Cloud::Storage::Project) }
  let(:bucket) { instance_double(Google::Cloud::Storage::Bucket) }
  let(:duckdb_conn) { instance_double(DuckDB::Connection) }
  let(:query_result) { instance_double("DuckDB::Result") }
  
  let(:connection_config) do
    {
      "user_id" => "test-user",
      "audience_id" => "test-audience"
    }
  end

  # Create a hash representation of the sync config
  let(:sync_config_hash) do
    {
      "source" => {
        "name" => "Audience",
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
        "name" => "Audience File Content Query",
        "query" => "SELECT * FROM audience_data",
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
    # Mock environment variables
    allow(ENV).to receive(:[]).with('AUDIENCE_PROJECT_ID').and_return('test-project')
    allow(ENV).to receive(:[]).with('AUDIENCE_CLIENT_EMAIL').and_return('test@example.com')
    allow(ENV).to receive(:[]).with('AUDIENCE_PRIVATE_KEY').and_return('-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n')
    allow(ENV).to receive(:[]).with('AUDIENCE_BUCKET').and_return('test-bucket')
    allow(ENV).to receive(:[]).with(anything).and_call_original

    # Common setup for file_double
    allow(file_double).to receive(:name).and_return("test-user/test-audience/data_20240101_120000.csv")
    allow(file_double).to receive(:updated_at).and_return(Time.now)
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
        allow(storage_client).to receive(:bucket).with(any_args).and_return(bucket)
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
        allow(storage_client).to receive(:bucket).with(any_args).and_return(bucket)
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
        allow(storage_client).to receive(:bucket).with(any_args).and_return(bucket)
        allow(bucket).to receive(:exists?).and_return(true)
        allow(bucket).to receive(:nil?).and_return(false)
        allow(client).to receive(:list_files).with(bucket).and_return([])
        
        # Call the method
        message = client.check_connection(connection_config)
        result = message.connection_status
        
        # Assertions
        expect(result.status).to eq("failed")
        expect(result.message).to include("No CSV files found")
      end
    end
    
    context "when required parameters are missing" do
      it "returns a failed connection status with missing parameters message" do
        # Setup incomplete config
        incomplete_config = {
          "user_id" => "",
          "audience_id" => "test-audience"
        }
        
        # Call the method
        message = client.check_connection(incomplete_config)
        result = message.connection_status
        
        # Assertions
        expect(result.status).to eq("failed")
        expect(result.message).to include("User ID and Audience ID are required")
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
        allow(storage_client).to receive(:bucket).with(any_args).and_return(bucket)
        allow(client).to receive(:list_files).with(bucket).and_return(files_array)
        allow(client).to receive(:get_latest_file).with(files_array).and_return(file_double)
        
        # Mock CSV parsing
        csv_double = double("CSV")
        csv_headers = ["id", "name"]
        allow(CSV).to receive(:parse).and_return(csv_double)
        allow(csv_double).to receive(:headers).and_return(csv_headers)
        
        # Call the method
        message = client.discover(connection_config)
        catalog = message.catalog
        
        # Assertions
        expect(catalog.streams).not_to be_empty
        expect(catalog.streams.first.name).to eq("audience_data_test-user_test-audience")
        expect(catalog.streams.first.json_schema["properties"]).to include("id", "name")
      end
    end

    context "when no files are found" do
      it "returns an empty catalog" do
        # Setup mocks
        allow(client).to receive(:create_storage_client).and_return(storage_client)
        allow(storage_client).to receive(:bucket).with(any_args).and_return(bucket)
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
            context: "AUDIENCE:DISCOVER:EXCEPTION",
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
        query_results = [{"id" => "1", "name" => "Test User"}, {"id" => "2", "name" => "Another User"}]
        allow(client).to receive(:get_results).with("SELECT * FROM audience_data").and_return(query_results)
        
        # Call the method
        records = client.read(sync_config)
        
        # Assertions
        expect(records).to be_an(Array)
        expect(records.size).to eq(2)
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(records.first.record.data).to eq({"id" => "1", "name" => "Test User"})
        expect(records.last.record.data).to eq({"id" => "2", "name" => "Another User"})
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
        batched_query = "SELECT * FROM audience_data LIMIT 10 OFFSET 5"
        query_results = [{"id" => "6", "name" => "User 6"}]
        allow(client).to receive(:batched_query).with("SELECT * FROM audience_data", 10, 5).and_return(batched_query)
        allow(client).to receive(:get_results).with(batched_query).and_return(query_results)
        
        # Call the method
        records = client.read(sync_config_with_limit)
        
        # Assertions
        expect(records).to be_an(Array)
        expect(records.size).to eq(1)
        expect(records.first.record.data).to eq({"id" => "6", "name" => "User 6"})
      end
    end

    context "when no query is provided" do
      it "reads records directly from GCS files" do
        # Setup sync_config with empty query
        sync_config_no_query = sync_config.dup
        
        # Create a new model with empty query
        model = Multiwoven::Integrations::Protocol::Model.new(
          name: "Audience File Content Query",
          query: "",
          query_type: "raw_sql",
          primary_key: "id"
        )
        
        # Set the model on the sync_config
        sync_config_no_query.model = model
        
        # Setup mocks
        allow(client).to receive(:create_storage_client).and_return(storage_client)
        allow(storage_client).to receive(:bucket).with(any_args).and_return(bucket)
        allow(client).to receive(:list_files).with(bucket).and_return(files_array)
        allow(client).to receive(:get_latest_file).with(files_array).and_return(file_double)
        
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
            context: "AUDIENCE:READ:EXCEPTION",
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
      query_results = [{"id" => "1", "name" => "Test User"}]
      allow(client).to receive(:get_results).with("SELECT * FROM audience_data").and_return(query_results)
      
      # Call the method
      records = client.query(duckdb_conn, "SELECT * FROM audience_data")
      
      # Assertions
      expect(records).to be_an(Array)
      expect(records.size).to eq(1)
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
      expect(records.first.record.data).to eq({"id" => "1", "name" => "Test User"})
    end
  end

  describe "#get_results" do
    before do
      # Set up instance variables directly
      client.instance_variable_set(:@bucket, "test-bucket")
      
      allow(client).to receive(:create_storage_client).and_return(storage_client)
      allow(storage_client).to receive(:bucket).with(any_args).and_return(bucket)
      allow(client).to receive(:list_files).with(bucket).and_return(files_array)
      allow(client).to receive(:get_latest_file).with(files_array).and_return(file_double)
      
      # Mock Dir and FileUtils
      allow(Dir).to receive(:mktmpdir).and_return("/tmp/audience_query")
      allow(File).to receive(:join).and_return("/tmp/audience_query/data_20240101_120000.csv")
      allow(File).to receive(:basename).and_return("data_20240101_120000.csv")
      allow(Dir).to receive(:exist?).and_return(true)
      allow(FileUtils).to receive(:remove_entry)
      
      # Mock DuckDB connection
      client.instance_variable_set(:@duckdb_conn, duckdb_conn)
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
      results = client.send(:get_results, "SELECT * FROM audience_data")
      
      # Assertions
      expect(results).to be_an(Array)
      expect(results.size).to eq(1)
      expect(results.first).to eq({"id" => "1", "name" => "Test User"})
    end
    
    it "handles empty file list" do
      # Setup mocks for empty file list
      allow(client).to receive(:list_files).with(bucket).and_return([])
      
      # Call the private method
      results = client.send(:get_results, "SELECT * FROM audience_data")
      
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
          context: "AUDIENCE:QUERY:EXCEPTION",
          type: "error"
        })
        # Return an empty array to satisfy the test
        []
      end
      
      # Call the private method
      result = client.send(:get_results, "SELECT * FROM audience_data")
      
      # Assertions
      expect(result).to eq([])
    end
  end

  describe "#get_latest_file" do
    it "returns the latest file based on timestamp in filename" do
      # Setup multiple files with different timestamps
      file1 = instance_double(Google::Cloud::Storage::File)
      file2 = instance_double(Google::Cloud::Storage::File)
      file3 = instance_double(Google::Cloud::Storage::File)
      
      allow(file1).to receive(:name).and_return("data_20240101_120000.csv")
      allow(file2).to receive(:name).and_return("data_20240102_120000.csv") # Latest
      allow(file3).to receive(:name).and_return("data_20231231_120000.csv")
      
      allow(file1).to receive(:updated_at).and_return(Time.now - 86400)
      allow(file2).to receive(:updated_at).and_return(Time.now)
      allow(file3).to receive(:updated_at).and_return(Time.now - 172800)
      
      files = [file1, file2, file3]
      
      # Call the private method
      latest = client.send(:get_latest_file, files)
      
      # Assertions
      expect(latest).to eq(file2)
    end
    
    it "returns nil for empty file list" do
      # Call the private method
      latest = client.send(:get_latest_file, [])
      
      # Assertions
      expect(latest).to be_nil
    end
    
    it "uses updated_at as fallback when no timestamp in filename" do
      # Setup files without timestamps in names
      file1 = instance_double(Google::Cloud::Storage::File)
      file2 = instance_double(Google::Cloud::Storage::File)
      
      allow(file1).to receive(:name).and_return("data.csv")
      allow(file2).to receive(:name).and_return("data_backup.csv")
      
      allow(file1).to receive(:updated_at).and_return(Time.now - 86400)
      allow(file2).to receive(:updated_at).and_return(Time.now) # Latest
      
      files = [file1, file2]
      
      # Call the private method
      latest = client.send(:get_latest_file, files)
      
      # Assertions
      expect(latest).to eq(file2)
    end
  end

  describe "#batched_query" do
    it "adds LIMIT and OFFSET to a query" do
      # Call the private method
      result = client.send(:batched_query, "SELECT * FROM audience_data", 10, 5)
      
      # Assertions
      expect(result).to eq("SELECT * FROM audience_data LIMIT 10 OFFSET 5")
    end
    
    it "removes trailing semicolon before adding LIMIT and OFFSET" do
      # Call the private method
      result = client.send(:batched_query, "SELECT * FROM audience_data;", 10, 5)
      
      # Assertions
      expect(result).to eq("SELECT * FROM audience_data LIMIT 10 OFFSET 5")
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
    it "sets instance variables from connection config and environment variables" do
      # Setup environment variables for this specific test
      allow(ENV).to receive(:[]).with('AUDIENCE_PROJECT_ID').and_return('test-project')
      allow(ENV).to receive(:[]).with('AUDIENCE_CLIENT_EMAIL').and_return('test@example.com')
      allow(ENV).to receive(:[]).with('AUDIENCE_PRIVATE_KEY').and_return('-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n')
      allow(ENV).to receive(:[]).with('AUDIENCE_BUCKET').and_return('test-bucket')
      allow(ENV).to receive(:[]).with(anything).and_call_original
      
      # Call the private method with a fresh client to avoid interference from before block
      fresh_client = Multiwoven::Integrations::Source::Audience::Client.new
      fresh_client.send(:initialize_client, connection_config)
      
      # Assertions
      expect(fresh_client.instance_variable_get(:@user_id)).to eq("test-user")
      expect(fresh_client.instance_variable_get(:@audience_id)).to eq("test-audience")
      expect(fresh_client.instance_variable_get(:@project_id)).to eq("test-project")
      expect(fresh_client.instance_variable_get(:@client_email)).to eq("test@example.com")
      expect(fresh_client.instance_variable_get(:@private_key)).to eq("-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n")
      expect(fresh_client.instance_variable_get(:@bucket)).to eq("test-bucket")
      expect(fresh_client.instance_variable_get(:@path)).to eq("/test-user/test-audience")
      expect(fresh_client.instance_variable_get(:@file_type)).to eq("csv")
    end
  end

  describe "#generate_path" do
    it "generates the correct path from user_id and audience_id" do
      # Call the private method
      path = client.send(:generate_path, "test-user", "test-audience")
      
      # Assertions
      expect(path).to eq("/test-user/test-audience")
    end
  end

  describe "#list_files" do
    it "lists files with the correct prefix and filters by file type" do
      # Setup mocks
      allow(bucket).to receive(:files).with(prefix: "test-user/test-audience").and_return(files_array)
      
      # Setup client instance variables
      client.instance_variable_set(:@path, "/test-user/test-audience")
      client.instance_variable_set(:@file_type, "csv")
      
      # Call the private method
      result = client.send(:list_files, bucket)
      
      # Assertions
      expect(result).to eq(files_array)
    end
    
    it "handles nil result from bucket.files" do
      # Setup mocks
      allow(bucket).to receive(:files).with(prefix: "test-user/test-audience").and_return(nil)
      
      # Setup client instance variables
      client.instance_variable_set(:@path, "/test-user/test-audience")
      client.instance_variable_set(:@file_type, "csv")
      
      # Call the private method
      result = client.send(:list_files, bucket)
      
      # Assertions
      expect(result).to eq([])
    end
  end
end
