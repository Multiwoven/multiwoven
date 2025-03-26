# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Audience::Client do
  let(:client) { Multiwoven::Integrations::Source::Audience::Client.new }
  let(:storage_client) { instance_double(Google::Cloud::Storage::Project) }
  let(:bucket) { instance_double(Google::Cloud::Storage::Bucket) }
  let(:conn) { instance_double(DuckDB::Connection) }
  let(:query_result) { instance_double("DuckDB::Result") }
  
  let(:sync_config) do
    {
      "source": {
        "name": "Audience",
        "type": "source",
        "connection_specification": {
          "user_id": "test-user",
          "audience_id": "test-audience"
        }
      },
      "destination": {
        "name": "Sample Destination Connector",
        "type": "destination",
        "connection_specification": {
          "example_destination_key": "example_destination_value"
        }
      },
      "model": {
        "name": "Audience File Content Query",
        "query": "SELECT * FROM 'gs://test-bucket/test-file.csv'",
        "query_type": "raw_sql",
        "primary_key": "id"
      },
      "stream": {
        "name": "example_stream",
        "action": "create",
        "json_schema": { "field1": "type1" },
        "supported_sync_modes": %w[full_refresh incremental],
        "source_defined_cursor": true,
        "default_cursor_field": ["field1"],
        "source_defined_primary_key": [["field1"], ["field2"]],
        "namespace": "exampleNamespace",
        "url": "https://storage.googleapis.com/test-bucket",
        "method": "GET"
      },
      "sync_id": "1",
      "sync_mode": "incremental",
      "cursor_field": "",
      "destination_sync_mode": "upsert"
    }
  end

  before do
    # Mock environment variables
    allow(ENV).to receive(:[]).with('AUDIENCE_PROJECT_ID').and_return('test-project')
    allow(ENV).to receive(:[]).with('AUDIENCE_CLIENT_EMAIL').and_return('test@example.com')
    allow(ENV).to receive(:[]).with('AUDIENCE_PRIVATE_KEY').and_return('-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n')
    allow(ENV).to receive(:[]).with('AUDIENCE_BUCKET').and_return('test-bucket')
    allow(ENV).to receive(:[]).with(anything).and_call_original
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(Google::Cloud::Storage).to receive(:new).and_return(storage_client)
        allow(storage_client).to receive(:bucket).with("test-bucket").and_return(bucket)
        allow(bucket).to receive(:exists?).and_return(true)
        
        files_double = [instance_double(Google::Cloud::Storage::File)]
        allow(bucket).to receive(:files).with(prefix: "users/test-user/audiences/test-audience").and_return(files_double)
        allow(files_double.first).to receive(:name).and_return("test-file.csv")

        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        
        expect(result.status).to eq("succeeded")
        expect(result.message).to include("Successfully connected")
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(Google::Cloud::Storage).to receive(:new).and_raise(StandardError, "Connection failed")
        
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
    
    context "when required parameters are missing" do
      it "returns a failed connection status with missing parameters message" do
        incomplete_config = {
          "user_id": "",
          "audience_id": "test-audience"
        }
        
        message = client.check_connection(incomplete_config)
        result = message.connection_status
        
        expect(result.status).to eq("failed")
        expect(result.message).to include("User ID and Audience ID are required")
      end
    end
  end

  describe "#read" do
    context "when using SQL query" do
      it "processes the query and returns records" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        
        connection_hash = {
          project_id: "test-project",
          client_email: "test@example.com",
          private_key: "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n",
          bucket: "test-bucket",
          path: "/users/test-user/audiences/test-audience",
          file_type: "csv"
        }
        
        allow(client).to receive(:create_connection).and_return(connection_hash)
        allow(client).to receive(:get_results).with(connection_hash, "SELECT * FROM 'gs://test-bucket/test-file.csv'")
                                             .and_return([{ "id" => "1", "name" => "Test" }])
        
        records = client.read(s_config)
        
        expect(records).to be_an(Array)
        expect(records).not_to be_empty
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(records.first.record.data).to eq({ "id" => "1", "name" => "Test" })
      end
    end

    it "reads records successfully for batched_query" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      s_config.limit = 100
      s_config.offset = 1
      
      connection_hash = {
        project_id: "test-project",
        client_email: "test@example.com",
        private_key: "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n",
        bucket: "test-bucket",
        path: "/users/test-user/audiences/test-audience",
        file_type: "csv"
      }
      
      allow(client).to receive(:create_connection).and_return(connection_hash)
      allow(client).to receive(:get_results)
                                     .with(connection_hash, "SELECT * FROM 'gs://test-bucket/test-file.csv' LIMIT 100 OFFSET 1")
                                     .and_return([{ "id" => "1", "name" => "Test" }])
      
      records = client.read(s_config)
      
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "reads records from GCS files when no query is provided" do
      # Create a modified sync_config with an empty query
      modified_config = sync_config.dup
      modified_config[:model] = modified_config[:model].dup
      modified_config[:model][:query] = ""

      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(modified_config.to_json)

      allow(Google::Cloud::Storage).to receive(:new).and_return(storage_client)
      allow(storage_client).to receive(:bucket).and_return(bucket)
      
      files_double = [instance_double(Google::Cloud::Storage::File)]
      allow(bucket).to receive(:files).with(prefix: "users/test-user/audiences/test-audience").and_return(files_double)

      file_double = files_double.first
      allow(file_double).to receive(:name).and_return("test-file.csv")
      allow(file_double).to receive(:download).and_return("id,name\n1,Test")

      records = client.read(s_config)

      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "handles read failure" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      s_config.sync_run_id = "2"

      allow(client).to receive(:create_connection).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError), {
          context: "AUDIENCE:READ:EXCEPTION",
          type: "error",
          sync_id: "1",
          sync_run_id: "2"
        }
      )
      
      client.read(s_config)
    end
  end

  describe "#discover" do
    it "discovers schema from CSV files" do
      allow(Google::Cloud::Storage).to receive(:new).and_return(storage_client)
      allow(storage_client).to receive(:bucket).with("test-bucket").and_return(bucket)
      
      files_double = [instance_double(Google::Cloud::Storage::File)]
      allow(bucket).to receive(:files).with(prefix: "users/test-user/audiences/test-audience").and_return(files_double)
      allow(files_double.first).to receive(:name).and_return("test-file.csv")
      allow(files_double.first).to receive(:download).and_return("id,name\n1,Test")

      message = client.discover(sync_config[:source][:connection_specification])
      catalog = message.catalog
      
      expect(catalog.streams).not_to be_empty
      expect(catalog.streams.first.name).to eq("audience_data_test-user_test-audience")
      expect(catalog.streams.first.json_schema["properties"]).to include("id", "name")
    end

    it "handles discover failure" do
      allow(Google::Cloud::Storage).to receive(:new).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError), {
          context: "AUDIENCE:DISCOVER:EXCEPTION",
          type: "error"
        }
      )
      
      client.discover(sync_config[:source][:connection_specification])
    end
  end
  
  describe "#generate_path" do
    it "generates the correct path from user_id and audience_id" do
      # Access the private method for testing
      path = client.send(:generate_path, "test-user", "test-audience")
      expect(path).to eq("/users/test-user/audiences/test-audience")
    end
  end
end
