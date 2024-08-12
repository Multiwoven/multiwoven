# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Http::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:mock_http_session) { double("Net::Http::Session") }
  let(:connection_config) do
    {
      destination_url: "https://www.google.com",
      headers: {
        test: "test",
        test1: "test1"
      }
    }.with_indifferent_access
  end

  let(:sync_config_json) do
    { source: {
        name: "DestinationConnectorName",
        type: "destination",
        connection_specification: {
          private_api_key: "test_api_key"
        }
      },
      destination: {
        name: "Http",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT * FROM CALL_CENTER LIMIT 1",
        query_type: "raw_sql",
        primary_key: "id"
      },
      sync_mode: "incremental",
      destination_sync_mode: "insert",
      stream: {
        name: "test",
        url: "test",
        request_method: "POST",
        json_schema: {
          type: "object",
          properties: {
            name: {
              type: %w[string null]
            }
          }
        }
      } }.with_indifferent_access
  end

  let(:records) do
    [{ name: "John Doe" }]
  end
  let(:csv_content) { "id,name\n1,Test Record\n" }

  describe "#check_connection" do
    context "when the connection is successful" do
      before do
        stub_request(:post, "https://www.google.com")
          .to_return(status: 200, body: "", headers: {})
      end

      it "returns a successful connection status" do
        response = client.check_connection(connection_config)
        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("succeeded")
      end
    end

    context "when the connection fails" do
      before do
        stub_request(:post, "https://www.google.com")
          .to_return(status: 404, body: "", headers: {})
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
      message = subject.discover
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.request_rate_limit).to eql(600)
      expect(catalog.request_rate_limit_unit).to eql("minute")
      expect(catalog.schema_mode).to eql("schemaless")
    end
  end

  describe "#write" do
    context "when the write operation is successful" do
      before do
        stub_request(:post, "https://www.google.com")
          .to_return(status: 200, body: "", headers: {})
      end

      it "increments the success count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(
          sync_config_json.to_json
        )
        response = client.write(sync_config, records)
        expect(response.tracking.success).to eq(records.size)
        expect(response.tracking.failed).to eq(0)
        log_message = response.tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("info")

        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end
    end

    context "when the write operation fails" do
      before do
        stub_request(:post, "https://www.google.com")
          .to_return(status: 400, body: "", headers: {})
      end

      it "increments the failure count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(
          sync_config_json.to_json
        )
        response = client.write(sync_config, records)
        expect(response.tracking.failed).to eq(records.size)
        expect(response.tracking.success).to eq(0)
        log_message = response.tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("info")

        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end
    end
  end

  def sync_config
    Multiwoven::Integrations::Protocol::SyncConfig.from_json(
      sync_config_json.to_json
    )
  end
end
