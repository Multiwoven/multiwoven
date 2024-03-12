# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Airtable::Client do # rubocop:disable Metrics/BlockLength
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      api_key: "test_api_key",
      base_id: "app43WSzJbarW7bTX"
    }
  end

  let(:json_schema) do
    {
      "$schema" => "https://json-schema.org/draft-07/schema#",
      "type" => "object",
      "additionalProperties" => true,
      "properties" => { "Name" => { "type" => %w[null string] } }
    }.with_indifferent_access
  end

  let(:sync_config_json) do
    {
      "source": {
        "name": "SourceConnectorName",
        "type": "source",
        "connection_specification": {
          "private_api_key": "test_api_key"
        }
      },
      "destination": {
        "name": "Airtable",
        "type": "destination",
        "connection_specification": connection_config
      },
      "model": {
        "name": "ExampleModel",
        "query": "SELECT * FROM CALL_CENTER LIMIT 1",
        "query_type": "raw_sql",
        "primary_key": "id"
      },

      "stream": {
        "name": "customer/Table_1",
        "url" => "https://api.airtable.com/v0/app43WSzJbarW7bTX/tblIcLe5KUHe7Yl5E",
        "action": "create",
        "method": "POST",
        "batch_support": true,
        "batch_size": 10,
        "json_schema": json_schema,
        "supported_sync_modes": %w[incremental],
        "source_defined_cursor": true,
        "cursor_field": "timestamp",
        "destination_sync_mode": "insert"
      },
      "sync_mode": "incremental",
      "cursor_field": "timestamp",
      "destination_sync_mode": "insert"
    }.with_indifferent_access
  end

  let(:records) do
    [
      { "Name" => "Alice" },
      { "Name" => "Bob" }
    ]
  end

  describe "#check_connection" do
    let(:success_response) { instance_double("Response", success?: true, body: "{\"data\": []}", code: 200) }
    let(:failure_response) { instance_double("Response", success?: false, body: "{\"error\": \"error_message\"}", code: 400) }

    it "returns a successful connection status if the request is successful" do
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).and_return(success_response)
      allow(client).to receive(:extract_data).with(success_response).and_return([{ "id" => "app43WSzJbarW7bTX" }])
      message = client.check_connection(connection_config)
      expect(message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
      result = message.connection_status
      expect(result.status).to eq(Multiwoven::Integrations::Protocol::ConnectionStatusType["succeeded"])
    end

    it "raises an error if the base idis not found in the response" do
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).and_return(success_response)
      allow(client).to receive(:extract_data).with(success_response).and_return([{ "id" => "invalid" }])
      message = client.check_connection(connection_config)
      expect(message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
      result = message.connection_status
      expect(result.status).to eq(Multiwoven::Integrations::Protocol::ConnectionStatusType["failed"])
      expect(result.message).to eq("base_id not found")
    end

    it "returns a failed connection status if the request is not successful" do
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).and_return(failure_response)
      message = client.check_connection(connection_config)
      expect(message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
      result = message.connection_status
      expect(result.status).to eq(Multiwoven::Integrations::Protocol::ConnectionStatusType["failed"])
    end
  end

  describe "#discover" do
    let(:base_response) do
      {
        bases: [
          { id: "app43WSzJbarW7bTX", name: "Test Base" }
        ]
      }.to_json
    end
    let(:schema_response) do
      {
        tables: [{ id: "table1", name: "Table 1" }]
      }.to_json
    end
    before do
      stub_request(:get, Multiwoven::Integrations::Core::Constants::AIRTABLE_BASES_ENDPOINT)
        .with(headers: { "Authorization" => "Bearer #{connection_config[:api_key]}" })
        .to_return(status: 200, body: base_response, headers: {})

      stub_request(:get, Multiwoven::Integrations::Core::Constants::AIRTABLE_GET_BASE_SCHEMA_ENDPOINT
      .gsub("{baseId}", connection_config[:base_id]))
        .with(headers: { "Authorization" => "Bearer #{connection_config[:api_key]}" })
        .to_return(status: 200, body: schema_response, headers: {})

      allow(Multiwoven::Integrations::Destination::Airtable::SchemaHelper)
        .to receive(:get_json_schema)
        .and_return(json_schema)
    end
    it "return catalog" do
      message = client.discover(connection_config)
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.request_rate_limit).to eql(300)
      expect(catalog.request_rate_limit_unit).to eql("minute")
      expect(catalog.request_rate_concurrency).to eql(10)
      expect(catalog.streams.count).to eql(1)
      expect(catalog.streams.first[:json_schema]).to eq(json_schema)
      expect(catalog.streams.first[:batch_support]).to eq(true)
      expect(catalog.streams.first[:supported_sync_modes]).to eq(%w[incremental])
    end
  end

  describe "#write" do
    let(:success_response) { instance_double("Response", success?: true, body: "{\"data\": []}", code: 200) }
    let(:failure_response) { instance_double("Response", success?: false, body: "{\"error\": \"error_message\"}", code: 400) }

    it "increments the success count" do
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).and_return(success_response)
      sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
      message = client.write(sync_config, records)
      expect(message.tracking.success).to eq(2)
      expect(message.tracking.failed).to eq(0)
    end

    it "increments the failure count" do
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).and_return(failure_response)
      sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
      message = client.write(sync_config, records)
      expect(message.tracking.success).to eq(0)
      expect(message.tracking.failed).to eq(2)
    end
  end

  describe "#create_payload" do
    it "returns the correct payload structure" do
      expected_payload = {
        "records" => [
          { "fields" => { "Name" => "Alice" } },
          { "fields" => { "Name" => "Bob" } }
        ]
      }

      payload = client.send(:create_payload, records)
      actual_payload = payload.deep_transform_keys(&:to_s)
      expect(actual_payload).to eq(expected_payload)
    end
  end
end
