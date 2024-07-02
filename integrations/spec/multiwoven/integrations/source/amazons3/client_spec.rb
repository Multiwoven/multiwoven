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
          "arn": ""
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
