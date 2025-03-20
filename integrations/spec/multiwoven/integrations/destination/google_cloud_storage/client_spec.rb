# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::GoogleCloudStorage::Client do
  let(:client) { Multiwoven::Integrations::Destination::GoogleCloudStorage::Client.new }
  let(:storage_client) { instance_double(Google::Cloud::Storage::Project) }
  let(:bucket) { instance_double(Google::Cloud::Storage::Bucket) }
  let(:file) { instance_double(Google::Cloud::Storage::File) }
  
  let(:sync_config) do
    {
      "source": {
        "name": "Sample Source Connector",
        "type": "source",
        "connection_specification": {
          "example_source_key": "example_source_value"
        }
      },
      "destination": {
        "name": "GoogleCloudStorage",
        "type": "destination",
        "connection_specification": {
          "project_id": "test-project",
          "bucket": "test-bucket",
          "credentials_json": "{\"type\":\"service_account\",\"project_id\":\"test-project\"}",
          "path": "data/",
          "file_type": "csv"
        }
      },
      "stream": {
        "name": "test_stream",
        "action": "create",
        "json_schema": { "field1": "type1" },
        "supported_sync_modes": %w[full_refresh incremental],
        "source_defined_cursor": true,
        "default_cursor_field": ["field1"],
        "source_defined_primary_key": [["field1"], ["field2"]],
        "namespace": "exampleNamespace"
      },
      "sync_id": "1",
      "sync_mode": "incremental",
      "cursor_field": "",
      "destination_sync_mode": "upsert",
      "sync_run_id": "2"
    }
  end

  let(:records) do
    [
      Multiwoven::Integrations::Protocol::MultiwovenMessage.new(
        type: Multiwoven::Integrations::Protocol::MessageType["record"],
        record: Multiwoven::Integrations::Protocol::RecordMessage.new(
          data: { "id" => 1, "name" => "Test 1" },
          emitted_at: Time.now.to_i
        )
      ),
      Multiwoven::Integrations::Protocol::MultiwovenMessage.new(
        type: Multiwoven::Integrations::Protocol::MessageType["record"],
        record: Multiwoven::Integrations::Protocol::RecordMessage.new(
          data: { "id" => 2, "name" => "Test 2" },
          emitted_at: Time.now.to_i
        )
      )
    ]
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(Google::Cloud::Storage).to receive(:new).and_return(storage_client)
        allow(storage_client).to receive(:bucket).with("test-bucket").and_return(bucket)
        allow(bucket).to receive(:exists?).and_return(true)
        
        message = client.check_connection(sync_config[:destination][:connection_specification])
        result = message.connection_status
        
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the bucket does not exist" do
      it "returns a failed connection status with an error message" do
        allow(Google::Cloud::Storage).to receive(:new).and_return(storage_client)
        allow(storage_client).to receive(:bucket).with("test-bucket").and_return(bucket)
        allow(bucket).to receive(:exists?).and_return(false)
        
        message = client.check_connection(sync_config[:destination][:connection_specification])
        result = message.connection_status
        
        expect(result.status).to eq("failed")
        expect(result.message).to include("does not exist")
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(Google::Cloud::Storage).to receive(:new).and_raise(StandardError, "Connection failed")
        
        message = client.check_connection(sync_config[:destination][:connection_specification])
        result = message.connection_status
        
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  describe "#discover" do
    it "returns a catalog with streams" do
      catalog_json = { "streams" => [{ "name" => "test_stream" }] }
      allow(client).to receive(:read_json).and_return(catalog_json)
      
      message = client.discover
      
      expect(message.catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(message.catalog.streams).to be_an(Array)
      expect(message.catalog.streams.first.name).to eq("test_stream")
    end

    it "handles discover failure" do
      allow(client).to receive(:read_json).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError), {
          context: "GOOGLECLOUDSTORAGE:DISCOVER:EXCEPTION",
          type: "error"
        }
      )
      
      client.discover
    end
  end

  describe "#write" do
    context "when writing is successful" do
      it "returns a success trace message" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        
        allow(Google::Cloud::Storage).to receive(:new).and_return(storage_client)
        allow(storage_client).to receive(:bucket).with("test-bucket").and_return(bucket)
        allow(bucket).to receive(:create_file).and_return(file)
        allow(Time).to receive_message_chain(:now, :strftime).and_return("20250320140000")
        
        result = client.write(s_config, records)
        
        expect(result).to be_an(Array)
        expect(result.first.type).to eq("TRACE")
        expect(result.first.trace.type).to eq("INFO")
        expect(result.first.trace.message).to include("Successfully uploaded 2 records")
      end
    end

    context "when writing fails" do
      it "handles the exception" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        
        allow(Google::Cloud::Storage).to receive(:new).and_raise(StandardError, "Write failed")
        expect(client).to receive(:handle_exception).with(
          an_instance_of(StandardError), {
            context: "GOOGLECLOUDSTORAGE:WRITE:EXCEPTION",
            type: "error",
            sync_id: "1",
            sync_run_id: "2"
          }
        )
        
        client.write(s_config, records)
      end
    end
  end
end
