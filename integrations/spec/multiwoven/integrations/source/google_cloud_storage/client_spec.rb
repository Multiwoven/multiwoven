# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::GoogleCloudStorage::Client do
    let(:client) { Multiwoven::Integrations::Source::GoogleCloudStorage::Client.new }
    let(:storage_client) { instance_double(Google::Cloud::Storage::Project) }
    let(:bucket) { instance_double(Google::Cloud::Storage::Bucket) }
    let(:conn) { instance_double(DuckDB::Connection) }
    let(:query_result) { instance_double("DuckDB::Result") }
    
    let(:sync_config) do
      {
        "source": {
          "name": "GoogleCloudStorage",
          "type": "source",
          "connection_specification": {
            "project_id": "test-project",
            "client_email": "test@example.com",
            "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n",
            "bucket": "test-bucket",
            "path": "test-path",
            "file_type": "csv"
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
          "name": "GCS File Content Query",
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
  
    describe "#check_connection" do
      context "when the connection is successful" do
        it "returns a succeeded connection status" do
          allow(Google::Cloud::Storage).to receive(:new).and_return(storage_client)
          allow(storage_client).to receive(:bucket).with("test-bucket").and_return(bucket)
          allow(bucket).to receive(:exists?).and_return(true)
          
          files_double = [instance_double(Google::Cloud::Storage::File)]
          allow(bucket).to receive(:files).with(prefix: "test-path").and_return(files_double)
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
            "project_id": "",
            "client_email": "test@example.com",
            "private_key": "key",
            "bucket": "test-bucket"
          }
          
          message = client.check_connection(incomplete_config)
          result = message.connection_status
          
          expect(result.status).to eq("failed")
          expect(result.message).to include("Neither PUB key nor PRIV key: no start line")
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
            path: "test-path",
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
          path: "test-path",
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
        allow(bucket).to receive(:files).with(prefix: "test-path").and_return(files_double)

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
            context: "GOOGLECLOUDSTORAGE:READ:EXCEPTION",
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
        connection_config = sync_config[:source][:connection_specification]
        
        allow(Google::Cloud::Storage).to receive(:new).and_return(storage_client)
        allow(storage_client).to receive(:bucket).and_return(bucket)
        
        files_double = [instance_double(Google::Cloud::Storage::File)]
        allow(bucket).to receive(:files).with(prefix: "test-path").and_return(files_double)

        file_double = files_double.first
        allow(file_double).to receive(:name).and_return("test-file.csv")
        allow(file_double).to receive(:download).and_return("id,name\n1,Test")

        message = client.discover(connection_config)

        expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
        first_stream = message.catalog.streams.first
        expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
        expect(first_stream.name).to eq("test-bucket_csv_files")
        expect(first_stream.json_schema).to be_an(Hash)
        expect(first_stream.json_schema["type"]).to eq("object")
        expect(first_stream.json_schema["properties"]).to include("id", "name")
      end

      it "handles discover failure" do
        connection_config = sync_config[:source][:connection_specification]

        allow(Google::Cloud::Storage).to receive(:new).and_raise(StandardError, "test error")
        expect(client).to receive(:handle_exception).with(
          an_instance_of(StandardError), {
            context: "GOOGLECLOUDSTORAGE:DISCOVER:EXCEPTION",
            type: "error"
          }
        )

        client.discover(connection_config)
      end
    end
  
    describe "#create_connection" do
      it "creates a connection hash with the correct parameters" do
        connection_config = sync_config[:source][:connection_specification]
        
        result = client.create_connection(connection_config)
        
        expect(result).to be_a(Hash)
        expect(result[:project_id]).to eq("test-project")
        expect(result[:client_email]).to eq("test@example.com")
        expect(result[:private_key]).to include("-----BEGIN PRIVATE KEY-----")
        expect(result[:bucket]).to eq("test-bucket")
        expect(result[:path]).to eq("test-path")
        expect(result[:file_type]).to eq("csv")
      end
      
      it "sets default path when not provided" do
        connection_config = sync_config[:source][:connection_specification].dup
        connection_config.delete(:path)
        
        result = client.create_connection(connection_config)
        
        expect(result[:path]).to eq("")
      end
    end
  
    describe "#query" do
      it "converts query results to record messages" do
        connection_hash = {
          project_id: "test-project",
          client_email: "test@example.com",
          private_key: "key",
          bucket: "test-bucket",
          path: "test-path",
          file_type: "csv"
        }
        
        allow(client).to receive(:get_results).with(connection_hash, "SELECT * FROM test")
                                       .and_return([{ "id" => "1", "name" => "Test" }])
        
        records = client.query(connection_hash, "SELECT * FROM test")
        
        expect(records).to be_an(Array)
        expect(records).not_to be_empty
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(records.first.record.data).to eq({ "id" => "1", "name" => "Test" })
      end
    end
  
    describe "#get_results" do
      let(:db) { instance_double(DuckDB::Database) }
      let(:dir_double) { instance_double(Dir) }
      let(:file_double) { instance_double(Google::Cloud::Storage::File) }
      
      before do
        allow(Google::Cloud::Storage).to receive(:new).and_return(storage_client)
        allow(storage_client).to receive(:bucket).and_return(bucket)

        files_double = [file_double]
        allow(bucket).to receive(:files).with(prefix: "test-path").and_return(files_double)

        allow(file_double).to receive(:name).and_return("test-file.csv")
        allow(Dir).to receive(:mktmpdir).and_return("/tmp/test-dir")
        allow(File).to receive(:join).and_return("/tmp/test-dir/test-file.csv")
        allow(file_double).to receive(:download)
        allow(DuckDB::Database).to receive(:open).and_return(db)
        allow(db).to receive(:connect).and_return(conn)
        allow(conn).to receive(:execute)
        allow(conn).to receive(:query).and_return(query_result)
        allow(query_result).to receive(:columns).and_return([double(name: "id"), double(name: "name")])
        allow(query_result).to receive(:each).and_yield(["1", "Test"])
        allow(Dir).to receive(:exist?).and_return(true)
        allow(FileUtils).to receive(:remove_entry)
      end
      
      it "processes CSV files and returns query results" do
        connection_hash = {
          project_id: "test-project",
          client_email: "test@example.com",
          private_key: "key",
          bucket: "test-bucket",
          path: "test-path",
          file_type: "csv"
        }
        
        results = client.send(:get_results, connection_hash, "SELECT * FROM test")
        
        expect(results).to be_an(Array)
        expect(results).not_to be_empty
        expect(results.first).to include("id" => "1", "name" => "Test")
      end
      
      it "handles query exceptions" do
        connection_hash = {
          project_id: "test-project",
          client_email: "test@example.com",
          private_key: "key",
          bucket: "test-bucket",
          path: "test-path",
          file_type: "csv"
        }
        
        allow(conn).to receive(:query).and_raise(StandardError, "Query failed")
        expect(client).to receive(:handle_exception).with(
          an_instance_of(StandardError), {
            context: "GOOGLECLOUDSTORAGE:QUERY:EXCEPTION",
            type: "error"
          }
        )
        
        client.send(:get_results, connection_hash, "SELECT * FROM test")
      end
    end
  
    describe "#batched_query" do
      it "appends LIMIT and OFFSET to query" do
        query = "SELECT * FROM read_csv_auto('gs://test-bucket/test-file.csv')"
        limit = 100
        offset = 10
        
        result = client.send(:batched_query, query, limit, offset)
        
        expect(result).to eq("SELECT * FROM read_csv_auto('gs://test-bucket/test-file.csv') LIMIT 100 OFFSET 10")
      end
      
      it "removes trailing semicolon before appending LIMIT and OFFSET" do
        query = "SELECT * FROM read_csv_auto('gs://test-bucket/test-file.csv');"
        limit = 100
        offset = 10
        
        result = client.send(:batched_query, query, limit, offset)
        
        expect(result).to eq("SELECT * FROM read_csv_auto('gs://test-bucket/test-file.csv') LIMIT 100 OFFSET 10")
      end
    end
end