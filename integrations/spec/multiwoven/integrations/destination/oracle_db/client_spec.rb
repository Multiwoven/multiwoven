# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Oracle::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      host: "localhost",
      port: "1521",
      servicename: "PDB1",
      username: "oracle_user",
      password: "oracle_password"
    }
  end
  let(:sync_config_json) do
    {
      source: {
        name: "Sample Source Connector",
        type: "source",
        connection_specification: {
          private_api_key: "test_api_key"
        }
      },
      destination: {
        name: "Databricks",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT col1, col2, col3 FROM test_table_1",
        query_type: "raw_sql",
        primary_key: "col1"
      },
      sync_mode: "incremental",
      destination_sync_mode: "insert",
      stream: {
        name: "table",
        action: "create",
        json_schema: {},
        supported_sync_modes: %w[incremental]
      }
    }
  end

  let(:oracle_connection) { instance_double(OCI8) }
  let(:cursor) { instance_double("OCI8::Cursor") }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(OCI8).to receive(:new).and_return(oracle_connection)
        allow(oracle_connection).to receive(:exec).and_return(true)
        message = client.check_connection(sync_config_json[:destination][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(client).to receive(:create_connection).and_raise(StandardError, "Connection failed")
        message = client.check_connection(sync_config_json[:destination][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  describe "#discover" do
    it "discovers schema successfully" do
      response = %w[test_table col1 NUMBER Y]
      allow(OCI8).to receive(:new).and_return(oracle_connection)
      allow(oracle_connection).to receive(:exec).and_return(cursor)
      allow(cursor).to receive(:fetch).and_return(response, nil)
      message = client.discover(sync_config_json[:destination][:connection_specification])
      expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
      first_stream = message.catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq("test_table")
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "col1" => { "type" => "string" } })
    end
  end

  describe "#write" do
    context "when the write operation is successful" do
      it "increments the success count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(
          sync_config_json.to_json
        )
        record = [
          { "col1" => 1, "col2" => "first", "col3" => 1.1 }
        ]
        allow(OCI8).to receive(:new).and_return(oracle_connection)
        allow(oracle_connection).to receive(:exec).and_return(1)
        allow(cursor).to receive(:fetch).and_return(1, nil)
        response = client.write(sync_config, record)
        expect(response.tracking.success).to eq(record.size)
        expect(response.tracking.failed).to eq(0)
        log_message = response.tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("info")
        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end
    end

    context "when the write operation fails" do
      it "increments the failure count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(
          sync_config_json.to_json
        )
        record = [
          { "col1" => 1, "col2" => "first", "col3" => 1.1 }
        ]
        allow(OCI8).to receive(:new).and_return(oracle_connection)
        allow(oracle_connection).to receive(:exec).and_raise(StandardError, "Test error")
        response = client.write(sync_config, record)
        expect(response.tracking.failed).to eq(record.size)
        expect(response.tracking.success).to eq(0)
        log_message = response.tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("error")
        expect(log_message.message).to include("request")
        expect(log_message.message).to include("{\"request\":\"INSERT INTO table (col1, col2, col3) VALUES ('1', 'first', '1.1')\",\"response\":\"Test error\",\"level\":\"error\"}")
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
end
