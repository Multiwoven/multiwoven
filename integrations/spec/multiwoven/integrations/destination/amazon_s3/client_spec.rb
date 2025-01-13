# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::AmazonS3::Client do
  let(:client) { described_class.new }

  let(:connection_config) do
    {
      region: "us-east-2",
      access_key_id: "Test",
      secret_access_key: "Test-Secret",
      bucket_name: "testbucket-ai2",
      folder_path: "test_folder/test_subfolder/",
      file_name: "test_file",
      format_type: "csv"
    }
  end

  let(:sync_config_json) do
    {
      source: {
        name: "DestinationConnectorName",
        type: "destination",
        connection_specification: {
          private_api_key: "test_api_key"
        }
      },
      destination: {
        name: "Sftp",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT * FROM CALL_CENTER LIMIT 1",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "sftp",
        action: "create",
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1,
        json_schema: {}
      },
      sync_mode: "incremental",
      cursor_field: "timestamp",
      destination_sync_mode: "insert"
    }.with_indifferent_access
  end

  let(:records) do
    [
      { "col1" => 1, "col2" => "first", "col3" => 1.1 },
      { "col1" => 2, "col2" => "second", "col3" => 2.2 },
      { "col1" => 3, "col2" => "third", "col3" => 3.3 }
    ]
  end

  let(:s3_client) { instance_double(Aws::S3::Client) }

  describe "#check_connection" do
    it "successfully checks connection" do
      allow_any_instance_of(Multiwoven::Integrations::Destination::AmazonS3::Client).to receive(:create_connection).and_return(s3_client)
      expect(s3_client).to receive(:head_bucket)
      message = client.check_connection(sync_config_json[:source][:connection_specification])
      result = message.connection_status
      expect(result.status).to eq("succeeded")
      expect(result.message).to be_nil
    end

    it "handles connection failure" do
      allow_any_instance_of(Multiwoven::Integrations::Destination::AmazonS3::Client).to receive(:create_connection).and_raise(StandardError.new("connection failed"))
      response = client.check_connection(connection_config)
      expect(response.connection_status.status).to eq("failed")
      expect(response.connection_status.message).to eq("connection failed")
    end
  end

  describe "#discover" do
    it "returns a catalog" do
      message = client.discover(connection_config)
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.request_rate_limit).to eql(600)
      expect(catalog.request_rate_limit_unit).to eql("minute")
      expect(catalog.request_rate_concurrency).to eql(10)
      expect(catalog.streams.count).to eql(1)
      expect(catalog.schema_mode).to eql("schemaless")
      expect(catalog.streams[0].name).to eql("create")
      expect(catalog.streams[0].batch_support).to eql(true)
      expect(catalog.streams[0].batch_size).to eql(100_000)
      expect(catalog.streams[0].supported_sync_modes).to eql(%w[full_refresh incremental])
    end
  end

  describe "#write" do
    context "when the write operation is successful" do
      it "increments the success count" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
        allow_any_instance_of(Multiwoven::Integrations::Destination::AmazonS3::Client).to receive(:create_connection).and_return(s3_client)
        expect(s3_client).to receive(:put_object)
        response = client.write(s_config, records)
        expect(response.tracking.success).to eq(records.size)
        expect(response.tracking.failed).to eq(0)
      end
    end

    context "when the write operation fails" do
      it "increments the failure count" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
        allow_any_instance_of(Multiwoven::Integrations::Destination::AmazonS3::Client).to receive(:create_connection).and_return(s3_client)
        allow(s3_client).to receive(:put_object).and_raise(StandardError.new("Simulated put_object failure"))
        expect(s3_client).to receive(:put_object)
        response = client.write(s_config, records)
        expect(response.tracking.failed).to eq(records.size)
        expect(response.tracking.success).to eq(0)
      end
    end
  end

  describe "#meta_data" do
    it "client class_name and meta name is same" do
      meta_name = client.class.to_s.split("::")[-2]
      expect(client.send(:meta_data)[:data][:name]).to eq(meta_name)
    end
  end
end
