# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Slack::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }

  let(:connection_config) do
    {
      api_token: "api_token",
      channel_id: "channel_id"
    }
  end

  let(:slack_json_schema) do
    catalog = client.discover.catalog
    catalog.streams.find { |stream| stream.name == "chat_postMessage" }.json_schema
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
        name: "Slack",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT * FROM CALL_CENTER LIMIT 1",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "chat_postMessage",
        action: "create",
        json_schema: slack_json_schema
      },
      sync_mode: "full_refresh",
      cursor_field: "timestamp",
      destination_sync_mode: "insert" }.with_indifferent_access
  end

  let(:records) do
    [
      build_record(1, "Account Name 1"),
      build_record(2, "Account Name 2")
    ]
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      before do
        stub_request(:post, "https://slack.com/api/auth.test")
          .to_return(status: 200, body: { "ok" => true, "app_name" => "mutiwoven-destination-connector", "app_id" => "A06ENPYVATG" }.to_json, headers: {})
      end

      it "returns a successful connection status" do
        response = client.check_connection(connection_config)

        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("succeeded")
      end
    end

    context "when the connection fails" do
      before do
        stub_request(:post, "https://slack.com/api/auth.test")
          .to_return(status: 200, body: { "ok": false, "error": "not_authed" }.to_json, headers: {})
      end

      it "returns a failed connection status with an error message" do
        response = client.check_connection(connection_config)

        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("failed")
        expect(response.connection_status.message).to eq("not_authed")
      end
    end
  end

  describe "#write" do
    context "when the write operation is successful" do
      before do
        stub_request(:post, "https://slack.com/api/chat.postMessage")
          .to_return(status: 200, body: "", headers: {})
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
        stub_request(:post, "https://slack.com/api/chat.postMessage")
          .to_return(status: 200, body: { "ok": false, "error": "not_authed" }.to_json, headers: {})
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

  private

  def build_record(id, name)
    {
      "data": { "attributes": { "Id": id, "Name": name } },
      "emitted_at": Time.now.to_i
    }
  end
end
