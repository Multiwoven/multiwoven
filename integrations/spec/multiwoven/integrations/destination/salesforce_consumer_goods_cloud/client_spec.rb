# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::SalesforceConsumerGoodsCloud::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      username: "username",
      password: "password",
      host: "test.salesforce.com",
      security_token: "security_token",
      client_id: "client_id",
      client_secret: "client_secret"
    }
  end

  let(:salesforce_account_json_schema) do
    catalog = client.discover(connection_config).catalog
    catalog.streams.find { |stream| stream["name"] == "Account" }["json_schema"]
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
        name: "Salesforce Consumer Goods Cloud",
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
        name: "Account",
        action: "create",
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1,
        json_schema: salesforce_account_json_schema
      },
      sync_mode: "incremental",
      cursor_field: "timestamp",
      destination_sync_mode: "insert" }.with_indifferent_access
  end

  let(:sample_user_schema) do
    {
      "name" => "User",
      "action" => "create",
      "json_schema" => {
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "title" => "User",
        "type" => "object",
        "batch_supported" => false,
        "additionalProperties" => true,
        "properties" => {
          "Id" => { "type" => "string" },
          "Username" => { "type" => "string" }
        }
      }
    }
  end

  let(:sample_account_schema) do
    {
      "name" => "Account",
      "action" => "create",
      "json_schema" => {
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "title" => "Account",
        "type" => "object",
        "batch_supported" => false,
        "additionalProperties" => true,
        "properties" => {
          "Id" => { "type" => "string" },
          "Name" => { "type" => %w[string null] }
        }
      }
    }
  end

  let(:sample_account_description) do
    {
      "name" => "Account",
      "fields" => [
        { "name" => "Id", "type" => "string" },
        { "name" => "Name", "type" => "string" }
      ]
    }
  end

  let(:sample_user_description) do
    {
      "name" => "User",
      "fields" => [
        { "name" => "Id", "type" => "string" },
        { "name" => "Username", "type" => "string" }
      ]
    }
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
    let(:records) do
      [
        { "Id" => "1", "Name" => "Account Name 1" },
        { "Id" => "2", "Name" => "Account Name 2" }
      ]
    end

    let(:success_response) do
      double("response", success?: true).tap do |response|
        allow(response).to receive(:[]).and_return(nil) # Assuming you want `[]` to return nil. Adjust if needed.
      end
    end

    let(:failure_response) do
      double("response", success?: false).tap do |response|
        allow(response).to receive(:[]).with("message").and_return("Error")
      end
    end

    before do
      stub_request(:post, "https://test.salesforce.com/services/oauth2/token")
        .with(
          body: { "client_id" => "client_id", "client_secret" => "client_secret", "grant_type" => "password", "password" => "passwordsecurity_token", "username" => "username" },
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Content-Type" => "application/x-www-form-urlencoded",
            "User-Agent" => "Faraday v2.8.1"
          }
        )
        .to_return(status: 200, body: "{\"access_token\":\"test_token\",\"instance_url\":\"https://test.salesforce.com\"}", headers: {})

      allow_any_instance_of(Restforce::Client).to receive(:describe).and_return(sample_account_description)
      allow(client).to receive(:initialize_client).with(sync_config.destination.connection_specification)
    end

    context "when the write operation is successful" do
      before do
        allow(client).to receive(:send_data_to_salesforce).and_return(success_response)
      end

      it "increments the success count" do
        response = client.write(sync_config, records)
        expect(response.tracking.success).to eq(records.size)
        expect(response.tracking.failed).to eq(0)
        expect(response.tracking.logs.count).to eql(2)
        log_message = response.tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("info")

        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end
    end

    context "when the write operation fails" do
      before do
        allow(client).to receive(:send_data_to_salesforce).and_raise(StandardError.new("Error"))
      end

      it "increments the failure count and does not raise an error" do
        expect { client.write(sync_config, records) }.not_to raise_error
        response = client.write(sync_config, records)
        expect(response.tracking.failed).to eq(records.size)
        expect(response.tracking.success).to eq(0)
        expect(response.tracking.logs.count).to eql(2)
        log_message = response.tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("error")

        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end
    end
  end

  describe "#meta_data" do
    it "serves it github image url as icon" do
      image_url = "https://raw.githubusercontent.com/Multiwoven/multiwoven/main/integrations/lib/multiwoven/integrations/destination/salesforce_consumer_goods_cloud/icon.svg"
      expect(client.send(:meta_data)[:data][:icon]).to eq(image_url)
    end
  end

  private

  def build_record(id, name)
    { "Id": id, "Name": name, NonListedField: "NonListedField Value" }
  end

  def stub_create_request(_id, _name, response_code)
    stub_request(:post, "https://test.salesforce.com/services/oauth2/token")
      .with(
        body: { "client_id" => "client_id", "client_secret" => "client_secret", "grant_type" => "password", "password" => "passwordsecurity_token", "username" => "username" },
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/x-www-form-urlencoded",
          "User-Agent" => "Faraday v2.8.1"
        }
      )
      .to_return(status: response_code, body: "", headers: {})
  end

  def sync_config
    Multiwoven::Integrations::Protocol::SyncConfig.from_json(
      sync_config_json.to_json
    )
  end

  describe "#discover" do
    context "when discovery is successful" do
      it "returns a MultiwovenMessage with the expected catalog structure" do
        allow(client).to receive(:initialize_client).with(connection_config.with_indifferent_access)
        allow(client).to receive(:load_catalog).and_return({ streams: [] })

        restforce_client_double = double("Restforce client")
        allow(client).to receive(:@client).and_return(restforce_client_double)

        allow(@client).to receive(:describe).with("Account").and_return(sample_account_description)
        allow(@client).to receive(:describe).with("User").and_return(sample_user_description)
        allow(@client).to receive(:describe).with("Visit").and_return(sample_account_description)
        allow(@client).to receive(:describe).with("RetailStore").and_return(sample_user_description)
        allow(@client).to receive(:describe).with("RecordType").and_return(sample_user_description)

        allow(client).to receive(:create_json_schema_for_object).and_return(sample_account_schema, sample_user_schema)

        result = client.discover(connection_config)
        expect(result).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(result.type).to eq("catalog")
      end
    end

    context "when discovery fails" do
      it "handles exceptions" do
        allow(client).to receive(:initialize_client).with(connection_config.with_indifferent_access)
        allow(client).to receive(:load_catalog).and_raise(StandardError.new("Discovery failed"))

        expect { client.discover(connection_config) }.to_not raise_error
      end
    end
  end
end
