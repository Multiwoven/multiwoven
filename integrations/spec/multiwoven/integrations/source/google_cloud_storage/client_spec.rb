# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::GoogleCloudStorage::Client do
  let(:client) { Multiwoven::Integrations::Source::GoogleCloudStorage::Client.new }
  let(:storage_client) { instance_double(Google::Cloud::Storage::Project) }
  let(:bucket) { instance_double(Google::Cloud::Storage::Bucket) }
  let(:conn) { instance_double(DuckDB::Connection) }
  
  let(:sync_config) do
    {
      "source": {
        "name": "GoogleCloudStorage",
        "type": "source",
        "connection_specification": {
          "project_id": "test-project",
          "bucket": "test-bucket",
          "credentials_json": "{\"type\":\"service_account\",\"project_id\":\"test-project\"}",
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
        
        # Mock DuckDB connection and query
        allow(DuckDB::Database).to receive_message_chain(:open, :connect).and_return(conn)
        allow(conn).to receive(:execute)
        allow(client).to receive(:get_results).and_return([])
        
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
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
  end

  describe "#read" do
    it "reads records successfully" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      
      allow(client).to receive(:create_connection).and_return(conn)
      allow(client).to receive(:get_results).and_return([{ Id: "1" }, { Id: "2" }])
      
      records = client.read(s_config)
      
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "reads records successfully for batched_query" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      s_config.limit = 100
      s_config.offset = 1
      
      allow(client).to receive(:create_connection).and_return(conn)
      allow(client).to receive(:get_results).and_return([{ Id: "1" }, { Id: "2" }])
      
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
      full_path = "gs://#{connection_config[:bucket]}/*.#{connection_config[:file_type]}"
      
      allow(client).to receive(:create_connection).and_return(conn)
      # Use the exact column name format expected by the build_discover_columns method
      allow(client).to receive(:get_results).and_return([{ "column_name" => "Id", "column_type" => "VARCHAR" }])
      
      message = client.discover(connection_config)
      
      expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
      first_stream = message.catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq(full_path)
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "Id" => { "type" => "string" } })
    end

    it "handles discover failure" do
      connection_config = sync_config[:source][:connection_specification]
      
      allow(client).to receive(:create_connection).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError), {
          context: "GOOGLECLOUDSTORAGE:DISCOVER:EXCEPTION",
          type: "error"
        }
      )
      
      client.discover(connection_config)
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
  end
end
