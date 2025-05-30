# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::IntuitQuickBooks::Client do
  let(:client) { Multiwoven::Integrations::Source::IntuitQuickBooks::Client.new }
  let(:sync_config_json) do
    {
      source: {
        name: "QuickBooks",
        type: "source",
        connection_specification: {
          client_id: ENV["QUICKBOOKS_CLIENT_ID"],
          client_secret: ENV["QUICKBOOKS_CLIENT_SECRET"],
          realm_id: ENV["QUICKBOOKS_REALM_ID"],
          refresh_token: ENV["QUICKBOOKS_REFRESH_TOKEN"],
          environment: "sandbox"
        }
      },
      destination: {
        name: "Sample Destination Connector",
        type: "destination",
        connection_specification: {
          example_destination_key: "example_destination_value"
        }
      },
      model: {
        name: "QuickBooks",
        query: "SELECT *  FROM Customer",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "example_stream",
        action: "create",
        json_schema: { "field1": "type1" },
        supported_sync_modes: %w[full_refresh incremental],
        source_defined_cursor: true,
        default_cursor_field: ["field1"],
        source_defined_primary_key: [["field1"], ["field2"]],
        namespace: "exampleNamespace",
        url: "https://api.example.com/data",
        method: "GET"
      },
      sync_mode: "full_refresh",
      cursor_field: "timestamp",
      destination_sync_mode: "upsert",
      sync_id: "1"
    }
  end

  let(:sync_config) { Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json) }
  before do
    allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
  end
  let(:headers) do
    {
      "Accept" => "application/json",
      "Authorization" => "Bearer #{ENV["QUICKBOOKS_ACCESS_TOKEN"]}",
      "Content-Type" => "application/json"
    }
  end

  let(:endpoint) { "https://sandbox-accounts.platform.intuit.com/v1/openid_connect/userinfo" }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        fake_response_body = {
          "QueryResponse" => {
            "Customer" => [
              { "Id" => "1", "DisplayName" => "John Doe" }
            ]
          }
        }.to_json
        fake_response = double("Response", code: 200, body: fake_response_body)
        allow(client).to receive(:send_request).and_return(fake_response)
        allow(client).to receive(:create_connection).and_return("dummy-access-token")
        message = client.check_connection(sync_config_json[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(client).to receive(:create_connection).and_raise(StandardError, "Connection failed")
        message = client.check_connection(sync_config_json[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  describe "#read" do
    it "reads records successfully" do
      fake_response_body = {
        "QueryResponse" => {
          "Customer" => [
            { "Id" => "1", "DisplayName" => "John Doe" },
            { "Id" => "2", "DisplayName" => "Jane Smith" }
          ]
        }
      }.to_json

      fake_response = instance_double("Response", body: fake_response_body)

      allow(client).to receive(:send_request).and_return(fake_response)
      allow(client).to receive(:create_connection).and_return("dummy-access-token")
      records = client.read(sync_config)
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "reads records successfully with limit" do
      sync_config.limit = 100
      sync_config.offset = 1
      fake_response_body = {
        "QueryResponse" => {
          "Customer" => [
            { "Id" => "1", "DisplayName" => "John Doe" },
            { "Id" => "2", "DisplayName" => "Jane Smith" }
          ]
        }
      }.to_json

      fake_response = instance_double("Response", body: fake_response_body)

      allow(client).to receive(:send_request).and_return(fake_response)
      allow(client).to receive(:create_connection).and_return("dummy-access-token")
      records = client.read(sync_config)
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "read records failure" do
      sync_config.sync_run_id = "2"
      allow(client).to receive(:create_connection).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError), {
          context: "INTUIT_QUICKBOOKS:READ:EXCEPTION",
          type: "error",
          sync_id: "1",
          sync_run_id: "2"
        }
      )
      client.read(sync_config)
    end
  end

  describe "#discover" do
    it "discovers schema successfully" do
      fake_response_body = {
        "QueryResponse" => {
          "Customer" => [
            { "Id" => "1", "DisplayName" => "John Doe" },
            { "Id" => "2", "DisplayName" => "Jane Smith" }
          ]
        }
      }.to_json

      fake_response = instance_double("Response", body: fake_response_body)

      allow(client).to receive(:send_request).and_return(fake_response)
      allow(client).to receive(:create_connection).and_return("dummy-access-token")
      message = client.discover(sync_config[:source][:connection_specification])
      expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
      first_stream = message.catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq("Customer")
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "Id" => { "type" => "string" }, "DisplayName" => { "type" => "string" } })
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
    it "defines a private #query method" do
      expect(described_class.private_instance_methods).to include(:query)
    end
  end
end
