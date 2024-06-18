# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Iterable::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      destination_url: "https://api.iterable.com/api",
      api_key: ENV["ITERABLEAPI"],
      catalog_name: "Test-API-Catalog",
      item_name: "Test-Api"
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
        name: "Iterable",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT col1, col2, col3 FROM test_table_1 LIMIT 10",
        query_type: "raw_sql",
        primary_key: "id"
      },
      sync_mode: "incremental",
      destination_sync_mode: "insert",
      stream: {
        name: "CatalogItems",
        action: "create",
        request_method: "PUT",
        json_schema: {
          type: "object",
          required: %w[catalog_name item_name key],
          properties: {
            catalog_name: { type: "string" },
            item_id: { type: "string" },
            item_attribute: { type: "string" }
          }
        }
      }
    }
  end

  let(:records) do
    [
      { "catalog_name" => "Test-API-Catalog", "item_id" => "Test-Api", "item_attribute" => "{\"Test1\":\"Value1\"}" },
      { "catalog_name" => "Test-API-Catalog", "item_id" => "Test-Api", "item_attribute" => "{ \"Test2\":2 }" },
      { "catalog_name" => "Test-API-Catalog", "item_id" => "Test-Api", "item_attribute" => "{ \"Test3\":true }" }
    ]
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      before do
        allow_any_instance_of(::Iterable::Channels).to receive(:all).and_return(double(success?: true))
      end
      it "returns a successful connection status" do
        response = client.check_connection(connection_config)
        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("succeeded")
      end
    end
    context "when the connection fails" do
      before do
        allow_any_instance_of(::Iterable::Channels).to receive(:all).and_return(double(success?: false))
      end
      it "returns a failed connection status with an error message" do
        response = client.check_connection(connection_config)
        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("failed")
      end
    end
  end

  describe "#discover" do
    it "returns a catalog" do
      message = client.discover
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.request_rate_limit).to eql(6000)
      expect(catalog.request_rate_limit_unit).to eql("minute")
      expect(catalog.request_rate_concurrency).to eql(10)
      message_stream = catalog.streams.first
      expect(message_stream.request_rate_limit).to eql(0)
      expect(message_stream.request_rate_limit_unit).to eql("minute")
      catalog.streams.each do |stream|
        expect(stream.supported_sync_modes).to eql(%w[incremental])
      end
    end
  end

  describe "#write" do
    context "when the write operation is successful" do
      before do
        allow_any_instance_of(::Iterable::CatalogItems).to receive(:create).and_return(double(success?: true))
      end

      it "increments the success count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(
          sync_config_json.to_json
        )
        response = client.write(sync_config, records)
        expect(response.tracking.success).to eq(records.size)
        expect(response.tracking.failed).to eq(0)
      end
    end

    context "when the write operation fails" do
      before do
        allow_any_instance_of(::Iterable::CatalogItems).to receive(:create).and_return(double(success?: false))
      end
      it "increments the failure count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(
          sync_config_json.to_json
        )
        response = client.write(sync_config, records)
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
