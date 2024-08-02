# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::DatabricksLakehouse::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      host: "https://adb-7377493381576663.3.azuredatabricks.net",
      api_token: ENV["DATABRICKS_API_TOKEN"],
      warehouse_id: ENV["DATABRICKS_WAREHOUSE_ID"],
      catalog: "hive_metastore",
      schema: "default",
      endpoint: "table sync"
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

  let(:faraday_connection) { instance_double(Faraday::Connection) }
  let(:response) { instance_double(Faraday::Response, status: 200, success?: true) }
  let(:faraday_connection2) { instance_double(Faraday::Connection) }
  let(:response2) { instance_double(Faraday::Response, status: 200, success?: true) }
  let(:table_response_body) { { "result" => { "data_array" => [%w[table_name test_table]] } }.to_json }
  let(:column_response_body) { { "result" => { "data_array" => [%w[col1 int YES], %w[col2 varchar YES], %w[col3 float YES]] } }.to_json }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(Faraday).to receive(:new).with(url: sync_config_json[:destination][:connection_specification][:host]).and_return(faraday_connection)
        allow(faraday_connection).to receive(:get).with("/api/2.0/clusters/list").and_return(response)
        allow(response).to receive(:status).and_return(200)
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
      body1 = {
        warehouse_id: connection_config[:warehouse_id],
        statement: "SHOW TABLES IN #{connection_config[:catalog]}.#{connection_config[:schema]};",
        wait_timeout: "15s"
      }
      body2 = {
        warehouse_id: connection_config[:warehouse_id],
        statement: "DESCRIBE TABLE #{connection_config[:catalog]}.#{connection_config[:schema]}.test_table;",
        wait_timeout: "15s"
      }
      call_count = 0
      allow(Faraday).to receive(:new).with(url: sync_config_json[:destination][:connection_specification][:host]).and_return(faraday_connection, faraday_connection2)

      allow(faraday_connection).to receive(:post) do |*args|
        call_count += 1
        if call_count == 1
          expect(args).to eq(["/api/2.0/sql/statements", body1.to_json])
        else
          expect(args).to eq(["/api/2.0/sql/statements", body2.to_json])
        end
        response
      end

      allow(response).to receive(:body) do
        call_count == 1 ? table_response_body : column_response_body
      end

      message = client.discover(sync_config_json[:destination][:connection_specification])
      expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
      first_stream = message.catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq("test_table")
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "col1" => { "type" => "string" }, "col2" => { "type" => "string" }, "col3" => { "type" => "string" } })
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
        body = {
          warehouse_id: connection_config[:warehouse_id],
          statement: "INSERT INTO hive_metastore.default.table (col1, col2, col3) VALUES ('1', 'first', '1.1');",
          wait_timeout: "15s"
        }
        allow(Faraday).to receive(:new).with(url: sync_config_json[:destination][:connection_specification][:host]).and_return(faraday_connection)
        allow(faraday_connection).to receive(:post).with("/api/2.0/sql/statements", body.to_json).and_return(response)
        allow(response).to receive(:status).and_return(200)
        response = client.write(sync_config, record)
        expect(response.tracking.success).to eq(record.size)
        expect(response.tracking.failed).to eq(0)
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
        body = {
          warehouse_id: connection_config[:warehouse_id],
          statement: "INSERT INTO hive_metastore.default.table (col1, col2, col3) VALUES ('1', 'first', '1.1');",
          wait_timeout: "15s"
        }
        allow(Faraday).to receive(:new).with(url: sync_config_json[:destination][:connection_specification][:host]).and_return(faraday_connection)
        allow(faraday_connection).to receive(:post).with("/api/2.0/sql/statements", body.to_json).and_return(response)
        allow(response).to receive(:status).and_return(400)
        response = client.write(sync_config, record)
        expect(response.tracking.failed).to eq(record.size)
        expect(response.tracking.success).to eq(0)
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
