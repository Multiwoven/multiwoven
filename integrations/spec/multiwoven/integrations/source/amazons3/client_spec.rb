# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::AmazonS3::Client do
  let(:client) { Multiwoven::Integrations::Source::AmazonS3::Client.new }
  let(:auth_data) do
    Aws::Credentials.new("AKIAEXAMPLE", "secretAccessKeyExample")
  end
  let(:sync_config) do
    {
      "source": {
        "name": "AmazonS3",
        "type": "source",
        "connection_specification": {
          "auth_type": "user",
          "region": "us-east-1",
          "bucket": "ai2-model-staging",
          "access_id": "accessid",
          "secret_access": "secretaccess",
          "file_type": "type",
          "arn": "",
          "external_id": ""
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
        "query": "SELECT * FROM 's3://ai2-model-staging/scrubbed_ml_leads.parquet",
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
      "sync_id": "1",
      "sync_mode": "incremental",
      "cursor_field": "",
      "destination_sync_mode": "upsert"
    }
  end

  let(:sts_client) { instance_double(Aws::STS::Client) }
  let(:conn) { instance_double(DuckDB::Connection) }

  let(:unstructured_config) do
    {
      "auth_type": "user",
      "region": "us-east-1",
      "bucket": "unstructured-bucket",
      "access_id": "accessid",
      "secret_access": "secretaccess",
      "data_type": "unstructured",
      "path": "test/",
      "arn": "",
      "external_id": ""
    }
  end

  let(:s3_resource) { instance_double(Aws::S3::Resource) }
  let(:s3_bucket) { instance_double(Aws::S3::Bucket) }
  let(:s3_objects) { instance_double(Aws::S3::ObjectSummary) }

  describe "#check_connection" do
    before do
      stub_request(:get, "https://ai2-model-staging.s3.amazonaws.com/?location").to_return(status: 200, body: "", headers: {})
    end
    context "when the connection is successful for 'user' auth_type" do
      it "returns a succeeded connection status" do
        allow_any_instance_of(Multiwoven::Integrations::Source::AmazonS3::Client).to receive(:get_auth_data).and_return(auth_data)
        allow_any_instance_of(Multiwoven::Integrations::Source::AmazonS3::Client).to receive(:get_results).and_return([{ Id: "1" }, { Id: "2" }])
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection is successful for 'role' auth_type" do
      it "returns a succeeded connection status" do
        sync_config[:source][:connection_specification][:auth_type] = "role"
        sync_config[:source][:connection_specification][:acess_id] = ""
        sync_config[:source][:connection_specification][:secret_access] = ""
        sync_config[:source][:connection_specification][:arn] = "aimrole/arn"
        sync_config[:source][:connection_specification][:external_id] = "aws-external-id-trust-relationship"
        allow_any_instance_of(Multiwoven::Integrations::Source::AmazonS3::Client).to receive(:get_auth_data).and_return(auth_data)
        allow_any_instance_of(Multiwoven::Integrations::Source::AmazonS3::Client).to receive(:get_results).and_return([{ Id: "1" }, { Id: "2" }])
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow_any_instance_of(Multiwoven::Integrations::Source::AmazonS3::Client).to receive(:get_auth_data).and_raise(StandardError, "Connection failed")
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end

    context "when checking unstructured data connection" do
      let(:s3_object_collection) { instance_double(Aws::S3::ObjectSummary::Collection) }

      before do
        allow(Aws::S3::Resource).to receive(:new).and_return(s3_resource)
        allow(s3_resource).to receive(:bucket).and_return(s3_bucket)
        allow(s3_bucket).to receive(:objects).and_return(s3_object_collection)
        allow(s3_object_collection).to receive(:limit).with(1).and_return(s3_object_collection)
        allow(s3_object_collection).to receive(:first).and_return(s3_objects)
      end

      it "returns a succeeded connection status for unstructured data" do
        allow_any_instance_of(Multiwoven::Integrations::Source::AmazonS3::Client).to receive(:get_auth_data).and_return(auth_data)
        message = client.check_connection(unstructured_config)
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end

      it "returns a failed connection status when unstructured data access fails" do
        allow_any_instance_of(Multiwoven::Integrations::Source::AmazonS3::Client).to receive(:get_auth_data).and_return(auth_data)
        allow(s3_bucket).to receive(:objects).and_raise(StandardError, "Access Denied")
        message = client.check_connection(unstructured_config)
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Access Denied")
      end
    end
  end
  # read and discover tests for AWS Athena
  describe "#read" do
    it "reads records successfully with 'user' auth_type" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      allow(client).to receive(:create_connection).and_return(conn)
      allow(client).to receive(:get_results).and_return([{ Id: "1" }, { Id: "2" }])
      records = client.read(s_config)
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "reads records successfully for batched_query with 'user' auth_type" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      s_config.limit = 100
      s_config.offset = 1
      allow(client).to receive(:get_auth_data).and_return(auth_data)
      allow(client).to receive(:create_connection).and_return(conn)
      allow(client).to receive(:get_results).and_return([{ Id: "1" }, { Id: "2" }])
      batched_query = client.send(:batched_query, s_config.model.query, s_config.limit, s_config.offset)
      allow(client).to receive(batched_query).and_return("SELECT * FROM S3Object LIMIT 100 OFFSET 1")
      records = client.read(s_config)
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "reads records successfully with 'role' auth_type" do
      sync_config[:source][:connection_specification][:auth_type] = "role"
      sync_config[:source][:connection_specification][:acess_id] = ""
      sync_config[:source][:connection_specification][:secret_access] = ""
      sync_config[:source][:connection_specification][:arn] = "aimrole/arn"
      sync_config[:source][:connection_specification][:external_id] = "aws-external-id-trust-relationship"
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      stub_request(:post, "https://sts.us-east-1.amazonaws.com/").to_return(status: 200, body: "", headers: {})
      allow(client).to receive(:get_auth_data).and_return(auth_data)
      allow(client).to receive(:create_connection).and_return(conn)
      allow(client).to receive(:get_results).and_return([{ Id: "1" }, { Id: "2" }])
      records = client.read(s_config)
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "reads records successfully for batched_query with 'role' auth_type" do
      sync_config[:source][:connection_specification][:auth_type] = "role"
      sync_config[:source][:connection_specification][:acess_id] = ""
      sync_config[:source][:connection_specification][:secret_access] = ""
      sync_config[:source][:connection_specification][:arn] = "aimrole/arn"
      sync_config[:source][:connection_specification][:external_id] = "aws-external-id-trust-relationship"
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      s_config.limit = 100
      s_config.offset = 1
      stub_request(:post, "https://sts.us-east-1.amazonaws.com/").to_return(status: 200, body: "", headers: {})
      allow(client).to receive(:get_auth_data).and_return(auth_data)
      allow(client).to receive(:create_connection).and_return(conn)
      allow(client).to receive(:get_results).and_return([{ Id: "1" }, { Id: "2" }])
      batched_query = client.send(:batched_query, s_config.model.query, s_config.limit, s_config.offset)
      allow(client).to receive(batched_query).and_return("SELECT * FROM S3Object LIMIT 100 OFFSET 1")
      records = client.read(s_config)
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "read records failure" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      s_config.sync_run_id = "2"
      allow(client).to receive(:create_connection).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError), {
          context: "AMAZONS3:READ:EXCEPTION",
          type: "error",
          sync_id: "1",
          sync_run_id: "2"
        }
      )
      client.read(s_config)
    end

    context "when reading unstructured data" do
      let(:unstructured_sync_config) do
        {
          "source": {
            "name": "AmazonS3",
            "type": "source",
            "connection_specification": unstructured_config
          },
          "destination": sync_config[:destination],
          "model": {
            "name": "List Files",
            "query": "list_files",
            "query_type": "raw_sql",
            "primary_key": "file_path"
          },
          "stream": {
            "name": "unstructured_files",
            "action": "fetch",
            "json_schema": {
              "type": "object",
              "properties": {
                "file_name": { "type": "string" },
                "file_path": { "type": "string" },
                "size": { "type": "integer" },
                "created_date": { "type": "string" },
                "modified_date": { "type": "string" }
              }
            }
          },
          "sync_id": "1",
          "sync_run_id": "123",
          "sync_mode": "incremental",
          "cursor_field": "",
          "destination_sync_mode": "upsert"
        }
      end

      before do
        allow(Aws::S3::Resource).to receive(:new).and_return(s3_resource)
        allow(s3_resource).to receive(:bucket).and_return(s3_bucket)
        allow(client).to receive(:unstructured_data?).and_return(true)
      end

      it "lists files successfully" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(unstructured_sync_config.to_json)
        allow(s3_bucket).to receive(:objects).and_return([s3_objects])
        allow(s3_objects).to receive(:key).and_return("test/file.pdf")
        allow(s3_objects).to receive(:content_length).and_return(1024)
        allow(s3_objects).to receive(:last_modified).and_return(Time.now)

        records = client.read(s_config)
        expect(records).to be_an(Array)
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(records.first.record.data[:file_name]).to eq("file.pdf")
        expect(records.first.record.data[:file_path]).to eq("test/file.pdf")
        expect(records.first.record.data[:size]).to eq(1024)
      end

      it "downloads file to temp path when FILE_DOWNLOAD_PATH is not set" do
        unstructured_sync_config[:model][:query] = 'download_file "test/file.pdf"'
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(unstructured_sync_config.to_json)

        temp_file = instance_double(Tempfile, path: "/tmp/s3_file/sync_runs/123/file.pdf")
        allow(Tempfile).to receive(:new).and_return(temp_file)

        s3_object = instance_double(Aws::S3::Object)
        allow(s3_bucket).to receive(:object).and_return(s3_object)
        allow(s3_object).to receive(:get)
        allow(s3_object).to receive(:content_length).and_return(1024)
        allow(s3_object).to receive(:last_modified).and_return(Time.now)

        records = client.read(s_config)
        expect(records).to be_an(Array)
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(records.first.record.data[:local_path]).to eq("/tmp/s3_file/sync_runs/123/file.pdf")
        expect(records.first.record.data[:file_type]).to eq("pdf")
      end

      context "when FILE_DOWNLOAD_PATH is set" do
        it "downloads file to custom path with sync_runs directory" do
          # Stub all ENV calls with a default value
          allow(ENV).to receive(:[]).and_return(nil)
          # Then specifically allow FILE_DOWNLOAD_PATH
          allow(ENV).to receive(:[]).with("FILE_DOWNLOAD_PATH").and_return("/custom/download/path")

          unstructured_sync_config[:model][:query] = 'download_file "test/file.pdf"'
          s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(unstructured_sync_config.to_json)

          s3_object = instance_double(Aws::S3::Object)
          allow(s3_bucket).to receive(:object).and_return(s3_object)
          allow(s3_object).to receive(:get)
          allow(s3_object).to receive(:content_length).and_return(1024)
          allow(s3_object).to receive(:last_modified).and_return(Time.now)

          records = client.read(s_config)
          expect(records).to be_an(Array)
          expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
          expect(records.first.record.data[:local_path]).to eq("/custom/download/path/syncs/1/file.pdf")
          expect(records.first.record.data[:file_type]).to eq("pdf")
        end
      end

      it "handles file not found error" do
        unstructured_sync_config[:model][:query] = 'download_file "test/nonexistent.pdf"'
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(unstructured_sync_config.to_json)

        s3_object = instance_double(Aws::S3::Object)
        allow(s3_bucket).to receive(:object).and_return(s3_object)
        allow(s3_object).to receive(:get).and_raise(Aws::S3::Errors::NoSuchKey.new(nil, nil))

        result = client.read(s_config)
        expect(result).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(result.type).to eq("log")
        expect(result.log.level).to eq("error")
        expect(result.log.message).to eq("File not found: test/nonexistent.pdf")
        expect(result.log.name).to eq("AMAZONS3:READ:EXCEPTION")
      end

      it "handles invalid command" do
        unstructured_sync_config[:model][:query] = "invalid_command"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(unstructured_sync_config.to_json)

        result = client.read(s_config)
        expect(result).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(result.type).to eq("log")
        expect(result.log.level).to eq("error")
        expect(result.log.message).to eq("Invalid command. Supported commands: list_files, download_file <file_path>")
        expect(result.log.name).to eq("AMAZONS3:READ:EXCEPTION")
      end
    end
  end

  describe "#discover" do
    it "discovers schema successfully with 'user' auth_type" do
      connection_config = sync_config[:source][:connection_specification]
      full_path = "s3://#{connection_config[:bucket]}/#{connection_config[:path]}*.#{connection_config[:file_type]}"
      allow(client).to receive(:get_auth_data).and_return(auth_data)
      allow(client).to receive(:create_connection).and_return(conn)
      allow(client).to receive(:get_results).and_return([{ Id: "1" }, { Id: "2" }])
      allow(client).to receive(:build_discover_columns).and_return([{ column_name: "Id", type: "string" }])
      message = client.discover(connection_config)
      expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
      first_stream = message.catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq(full_path)
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "Id" => { "type" => "string" } })
    end

    it "discovers schema successfully with 'role' auth_type" do
      sync_config[:source][:connection_specification][:auth_type] = "role"
      sync_config[:source][:connection_specification][:acess_id] = ""
      sync_config[:source][:connection_specification][:secret_access] = ""
      sync_config[:source][:connection_specification][:arn] = "aimrole/arn"
      sync_config[:source][:connection_specification][:external_id] = "aws-external-id-trust-relationship"
      connection_config = sync_config[:source][:connection_specification]
      full_path = "s3://#{connection_config[:bucket]}/#{connection_config[:path]}*.#{connection_config[:file_type]}"
      allow(client).to receive(:get_auth_data).and_return(auth_data)
      allow(client).to receive(:create_connection).and_return(conn)
      allow(client).to receive(:get_results).and_return([{ Id: "1" }, { Id: "2" }])
      allow(client).to receive(:build_discover_columns).and_return([{ column_name: "Id", type: "string" }])
      message = client.discover(connection_config)
      expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
      first_stream = message.catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq(full_path)
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "Id" => { "type" => "string" } })
    end

    it "discover schema failure" do
      allow(client).to receive(:create_connection).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError), {
          context: "AMAZONS3:DISCOVER:EXCEPTION",
          type: "error"
        }
      )
      client.discover(sync_config[:source][:connection_specification])
    end

    context "when discovering unstructured data" do
      it "returns unstructured stream for unstructured data" do
        allow_any_instance_of(Multiwoven::Integrations::Source::AmazonS3::Client).to receive(:get_auth_data).and_return(auth_data)
        message = client.discover(unstructured_config)
        expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
        expect(message.catalog.streams).to be_an(Array)
        expect(message.catalog.streams.first).to be_a(Multiwoven::Integrations::Protocol::Stream)
      end
    end
  end

  describe "#meta_data" do
    # change this to rollout validation for all connector rolling out
    it "client class_name and meta name is same" do
      meta_name = client.class.to_s.split("::")[-2]
      expect(client.send(:meta_data)[:data][:name]).to eq(meta_name)
    end
  end

  describe "method definition" do
    it "defines a private #create_connection method" do
      expect(described_class.private_instance_methods).to include(:create_connection)
    end

    it "defines a private #query method" do
      expect(described_class.private_instance_methods).to include(:query)
    end
  end
end
