# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::SalesforceCrm::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      oauth_token: "oauth_token",
      refresh_token: "refresh_token",
      instance_url: "https://your-instance-url.salesforce.com",
      client_id: "client_id",
      client_secret: "client_secret"
    }
  end

  let(:salesforce_account_json_schema) do
    catalog = client.discover.catalog
    catalog.streams.find { |stream| stream.name == "Account" }.json_schema
  end

  let(:sync_config) do
    {
      destination: {
        name: "Salesforce CRM",
        type: "destination",
        connection_specification: connection_config
      },
      stream: {
        name: "Account",
        action: "create",
        json_schema: salesforce_account_json_schema
      },
      sync_mode: "full_refresh",
      cursor_field: "timestamp",
      destination_sync_mode: "append"
    }.with_indifferent_access
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
        stub_request(:post, "https://login.salesforce.com/services/oauth2/token")
          .to_return(status: 200, body: "", headers: {})
      end

      it "returns a successful connection status" do
        allow(client).to receive(:authenticate_client).and_return(true)

        response = client.check_connection(connection_config)

        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("succeeded")
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(client).to receive(:authenticate_client).and_raise(StandardError.new("connection failed"))

        response = client.check_connection(connection_config)

        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("failed")
        expect(response.connection_status.message).to eq("connection failed")
      end
    end
  end

  describe "#write" do
    context "when the write operation is successful" do
      before do
        stub_create_request(1, "Account Name 1", 200)
        stub_create_request(2, "Account Name 2", 200)
      end

      it "increments the success count" do
        response = client.write(sync_config, records)

        expect(response.tracking.success).to eq(records.size)
        expect(response.tracking.failed).to eq(0)
      end
    end

    context "when the write operation fails" do
      before do
        stub_create_request(1, "Account Name 1", 403)
        stub_create_request(2, "Account Name 2", 403)
      end

      it "increments the failure count" do
        response = client.write(sync_config, records)

        expect(response.tracking.failed).to eq(records.size)
        expect(response.tracking.success).to eq(0)
      end
    end
  end

  private

  def build_record(id, name)
    Multiwoven::Integrations::Protocol::RecordMessage.new(
      data: { Id: id, Name: name, NonListedField: "NonListedField Value" },
      emitted_at: Time.now.to_i
    )
  end

  def stub_create_request(id, name, response_code)
    stub_request(:post, "https://your-instance-url.salesforce.com/services/data/v59.0/sobjects/Account")
      .with(
        body: hash_including("Id" => id, "Name" => name),
        headers: {
          "Accept" => "*/*",
          "Authorization" => "OAuth",
          "Content-Type" => "application/json"
        }
      ).to_return(status: response_code, body: "", headers: {})
  end
end
