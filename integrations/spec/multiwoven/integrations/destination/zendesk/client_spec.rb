# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Zendesk::Client do # rubocop:disable Metrics/BlockLength
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }

  let(:connection_config) do
    {
      subdomain: "https://your-subdomain",
      username: "username",
      password: "password"
    }
  end

  let(:zendesk_api_url) { "#{connection_config[:subdomain]}.zendesk.com/api/v2" }

  let(:records) do
    [
      { "ticket": { "subject": "test 1", "comment": { "body": "testing creating a ticket" } } },
      { "ticket": { "subject": "test 2", "comment": { "body": "testing creating a ticket" } } }
    ]
  end

  let(:source_connector) do
    {
      name: "Salesforce Consumer Goods Cloud",
      type: Multiwoven::Integrations::Protocol::ConnectorType["source"],
      connection_specification: {
        "username": "username",
        "password": "password",
        "host": "test.salesforce.com",
        "security_token": "security_token",
        "client_id": "client_id",
        "client_secret": "client_secret"
      }
    }
  end

  let(:destination_connector) do
    {
      name: "Test Zendesk Connector",
      type: Multiwoven::Integrations::Protocol::ConnectorType["destination"],
      connection_specification: connection_config
    }
  end

  let(:model) do
    {
      name: "Salesforce Account",
      query: "select id, name from Account LIMIT 10",
      query_type: Multiwoven::Integrations::Protocol::ModelQueryType["raw_sql"],
      primary_key: "id"
    }
  end

  let(:stream) do
    {
      name: "Tickets",
      action: "create",
      request_rate_limit: 500,
      request_rate_limit_unit: "day",
      request_rate_concurrency: 5,
      json_schema: {
        type: "object",
        additionalProperties: true,
        properties: {
          subject: {
            type: "string"
          },
          description: {
            type: "string"
          },
          priority: {
            type: "string",
            enum: %w[urgent high normal low]
          },
          status: {
            type: "string",
            enum: %w[new open pending hold solved closed]
          }
        }
      },
      supported_sync_modes: ["incremental"],
      source_defined_cursor: true,
      default_cursor_field: ["updated_at"],
      source_defined_primary_key: [["id"]]
    }
  end

  let(:zendesk_client_double) { instance_double(ZendeskAPI::Client) }
  let(:resource_double) { double("resource") }

  let(:sync_config) do
    Multiwoven::Integrations::Protocol::SyncConfig.new(
      source: source_connector,
      destination: destination_connector,
      model: model,
      stream: stream,
      sync_mode: Multiwoven::Integrations::Protocol::SyncMode["incremental"],
      destination_sync_mode: Multiwoven::Integrations::Protocol::DestinationSyncMode["insert"]
    )
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      before do
        stub_request(:post, zendesk_api_url)
          .to_return(status: 200, body: { "tickets": [] }.to_json, headers: {})
      end

      it "returns a successful connection status" do
        allow(client).to receive(:authenticate_client).and_return(true)

        response = client.check_connection(connection_config)

        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("succeeded")
      end
    end

    context "when the connection fails" do
      before do
        stub_request(:post, zendesk_api_url)
          .to_return(status: 401, body: "", headers: {})
      end

      it "returns a failed connection status with an error message" do
        allow(client).to receive(:authenticate_client).and_raise(StandardError.new("connection failed"))

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
      catalog.streams.each do |stream|
        expect(stream.supported_sync_modes).to eql(%w[incremental])
      end
    end
  end

  describe "#write" do
    context "when the write operation is successful" do
      it "increments the success count" do
        expect(ZendeskAPI::Client).to receive(:new).and_return(zendesk_client_double)
        allow(zendesk_client_double).to receive(:method_missing).with(:tickets).and_return(resource_double)
        allow(resource_double).to receive(:create!).and_return(true)
        result = client.write(sync_config, records)
        expect(result.tracking.success).to eq(records.size)
        expect(result.tracking.failed).to eq(0)
      end
    end

    context "when the write operation fails" do
      it "returns a failure status message" do
        expect(ZendeskAPI::Client).to receive(:new).and_return(zendesk_client_double)
        allow(zendesk_client_double).to receive(:method_missing).with(:tickets).and_return(resource_double)
        allow(resource_double).to receive(:create!).and_raise(StandardError.new("connection failed"))

        result = client.write(sync_config, records)
        expect(result.type).to eq("tracking") # Adjust based on your response handling
        expect(result.tracking.success).to eq(0)
        expect(result.tracking.failed).to eq(records.size)
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
