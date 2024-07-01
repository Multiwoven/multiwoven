# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::MariaDB::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      host: "127.0.0.1",
      port: "3306",
      username: "Test_service",
      password: ENV["MARIADB_PASSWORD"],
      database: "test_database"
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
        name: "MariaDB",
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
        name: "Test_Table",
        action: "create",
        json_schema: { "field1": "type1" },
        supported_sync_modes: %w[full_refresh incremental]
      }
    }
  end

  let(:sequel_client) { instance_double(Sequel::Database) }
  let(:table) { double("Table") }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow_any_instance_of(Multiwoven::Integrations::Destination::MariaDB::Client).to receive(:create_connection).and_return(sequel_client)
        message = client.check_connection(sync_config_json[:destination][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow_any_instance_of(Multiwoven::Integrations::Destination::MariaDB::Client).to receive(:create_connection).and_raise(StandardError, "Connection failed")
        message = client.check_connection(sync_config_json[:destination][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  describe "#discover" do
    it "discovers schema successfully" do
      dataset = [
        { table_name: "test_table", column_name: "col1", data_type: "int", is_nullable: "YES" },
        { table_name: "test_table", column_name: "col2", data_type: "varchar", is_nullable: "YES" },
        { table_name: "test_table", column_name: "col3", data_type: "float", is_nullable: "YES" }
      ]
      allow(sequel_client).to receive(:fetch).and_return(dataset)
      allow(client).to receive(:create_connection).and_return(sequel_client)

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
      before do
        allow_any_instance_of(Multiwoven::Integrations::Source::MariaDB::Client).to receive(:create_connection).and_return(sequel_client)
      end

      it "increments the success count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(
          sync_config_json.to_json
        )
        records = [
          { "table_name" => "external_table", "value_attribute" => { "Col1" => 400, "Col2" => 4.4, "Col3" => "Fourth" }.to_json },
          { "table_name" => "external_table", "value_attribute" => { "Col1" => 500, "Col2" => 5.5, "Col3" => "Fifth" }.to_json },
          { "table_name" => "external_table", "value_attribute" => { "Col1" => 600, "Col2" => 6.6, "Col3" => "Sixth" }.to_json }
        ]
        allow(client).to receive(:create_connection).and_return(sequel_client)
        allow(sequel_client).to receive(:run).and_return(nil)
        response = client.write(sync_config, records)
        expect(response.tracking.success).to eq(records.size)
        expect(response.tracking.failed).to eq(0)
      end
    end

    context "when the write operation fails" do
      before do
        allow_any_instance_of(Multiwoven::Integrations::Destination::MariaDB::Client).to receive(:create_connection).and_return(sequel_client)
      end
      it "increments the failure count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(
          sync_config_json.to_json
        )
        records = [
          { "table_name" => "external_table", "value_attribute" => { "Col1" => 400, "Col2" => 4.4, "Col3" => "Fourth" } },
          { "table_name" => "external_table", "value_attribute" => { "Col1" => 500, "Col2" => 5.5, "Col3" => "Fifth" } },
          { "table_name" => "external_table", "value_attribute" => { "Col1" => 600, "Col2" => 6.6, "Col3" => "Sixth" } }
        ]
        allow(client).to receive(:create_connection).and_return(sequel_client)
        allow(sequel_client).to receive(:run).and_raise(StandardError)
        response = client.write(sync_config, records)
        expect(response.tracking.failed).to eq(records.size)
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
