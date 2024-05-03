# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::AmazonS3::Client do # rubocop:disable Metrics/BlockLength
  let(:client) { Multiwoven::Integrations::Source::AmazonS3::Client.new }
  let(:sync_config) do
    {
      "source": {
        "name": "AmazonS3 Bucket Source",
        "type": "source",
        "connection_specification": {
          "region": "us-east-1",
          "bucket": ENV["S3_BUCKET_NAME"],
          "access_id": ENV["S3_ACCESS_ID"],
          "secret_access": ENV["S3_SECRET_ACCESS"],
          "file_key": "scrubbed_ml_leads.parquet",
          "file_type": "parquet"
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
        "name": "Amazon File Content Query",
        "query": "SELECT * FROM S3Object",
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
        "url": "https://api.example.com/data",
        "method": "GET"
      },
      "sync_mode": "full_refresh",
      "cursor_field": "timestamp",
      "destination_sync_mode": "upsert"
    }
  end

  let(:s3_client) { instance_double(Aws::S3::Client) }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow_any_instance_of(Multiwoven::Integrations::Source::AmazonS3::Client).to receive(:config_aws).and_return(s3_client)
        expect(s3_client).to receive(:head_object)
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow_any_instance_of(Multiwoven::Integrations::Source::AmazonS3::Client).to receive(:config_aws).and_raise(StandardError, "Connection failed")
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  # read and #discover tests for Amazon S3
  describe "#read" do
    it "reads records successfully" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      allow(client).to receive(:config_aws).and_return(s3_client)
      allow(client).to receive(:build_select_content_options).and_return({
        bucket: sync_config[:source][:connection_specification][:bucket],
        key: sync_config[:source][:connection_specification][:file_key],
        expression_type: "SQL",
        expression:sync_config[:model][:query],
        input_serialization: {
          parquet: {}
        },
        output_serialization: {
          json: {}
        }
      })
      allow(s3_client).to receive(:select_object_content).and_return([])
      records = client.read(s_config)
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end
end
