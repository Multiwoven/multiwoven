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
<<<<<<< HEAD
      expect(catalog.schema_mode).to eql("schemaless")
      expect(catalog.streams[0].name).to eql("create")
      expect(catalog.streams[0].batch_support).to eql(true)
      expect(catalog.streams[0].batch_size).to eql(100_000)
      expect(catalog.streams[0].supported_sync_modes).to eql(%w[full_refresh incremental])
=======
      expect(catalog.schema_mode).to eql("schema")
      expect(catalog.streams[0].name).to eql("test_file")
      expect(catalog.streams[0].batch_support).to eql(true)
      expect(catalog.streams[0].batch_size).to eql(100_000)
      expect(catalog.streams[0].supported_sync_modes).to eql(%w[incremental])
    end

    context "when the discover operation is successful for minIO" do
      it "returns a succeeded discover status" do
        sync_config_json[:source][:connection_specification][:endpoint] = "http://localhost:9000"
        sync_config_json[:source][:connection_specification][:path_style] = true
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
        allow_any_instance_of(Multiwoven::Integrations::Destination::AmazonS3::Client).to receive(:create_connection).and_return(s3_client)
        allow(s3_client).to receive(:list_objects_v2).and_return(
          Aws::S3::Types::ListObjectsV2Output.new(
            contents: [
              Aws::S3::Types::Object.new(
                key: "test_file.csv",
                size: 123,
                etag: '"abc123"',
                last_modified: Time.now,
                storage_class: "STANDARD"
              )
            ],
            key_count: 1,
            is_truncated: false,
            name: "my-bucket",
            prefix: "test_file.csv"
          )
        )
        allow(s3_client).to receive(:get_object).and_return(
          Aws::S3::Types::GetObjectOutput.new(
            body: StringIO.new("col1,col2,col3\n1,first,1.1\n2,second,2.2\n3,third,3.3")
          )
        )
        message = client.discover(s_config[:destination][:connection_specification])
        expect(message.catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
        expect(message.catalog.request_rate_limit).to eql(60)
        expect(message.catalog.request_rate_limit_unit).to eql("minute")
        expect(message.catalog.request_rate_concurrency).to eql(10)
        expect(message.catalog.streams.count).to eql(1)
        expect(message.catalog.schema_mode).to eql("schema")
        expect(message.catalog.streams[0].name).to eql("test_file")
        expect(message.catalog.streams[0].batch_support).to eql(true)
        expect(message.catalog.streams[0].batch_size).to eql(100_000)
        expect(message.catalog.streams[0].supported_sync_modes).to eql(%w[incremental])
      end
    end

    context "when the discover operation fails for minIO" do
      it "returns a failed discover status" do
        sync_config_json[:source][:connection_specification][:endpoint] = "http://localhost:9000"
        sync_config_json[:source][:connection_specification][:path_style] = true
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
        allow_any_instance_of(Multiwoven::Integrations::Destination::AmazonS3::Client).to receive(:create_connection).and_return(s3_client)
        allow(s3_client).to receive(:list_objects_v2).and_return(
          Aws::S3::Types::ListObjectsV2Output.new(
            contents: []
          )
        )
        expect(client).to receive(:handle_exception).with(
          an_instance_of(StandardError), {
            context: "AMAZONS3:DISCOVER:EXCEPTION",
            type: "error"
          }
        )
        client.discover(s_config[:destination][:connection_specification])
      end
>>>>>>> cb46584b6 (chore(CE): Allow Batch Support and Batch Size for S3 (#1632))
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
