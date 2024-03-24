# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::SalesforceConsumerGoodsCloud::Client do # rubocop:disable Metrics/BlockLength
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
    catalog.streams.find { |stream| stream.name == "Account" }.json_schema
  end

  let(:sync_config_json) do
    { source: {
        name: "DestinationConnectorName",
        type: "destination",
        connection_specification: connection_config
      },
      destination: {
        name: "Salesforce Consumer Goods Cloud",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT * FROM Account LIMIT 1",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "Account",
        action: "create",
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1,
        json_schema: {}
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

  describe "#read" do
    context "when read is successful" do
      it "returns an array of MultiwovenMessages with RecordMessages" do
        allow(client).to receive(:initialize_client)
        allow(client).to receive(:@client).and_return(double)

        sobject_one = Restforce::SObject.new("Id" => "1", "Name" => "Random COMPANY")
        sobject_two = Restforce::SObject.new("Id" => "2", "Name" => "Random COMPANY 2")
        query_result = [sobject_one, sobject_two]

        allow(client.instance_variable_get(:@client)).to receive(:query).and_return(query_result)

        results = client.read(sync_config)

        expect(results).to all(be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage))
        expect(results[0].record.data).to eq(sobject_one)
        expect(results[1].record.data).to eq(sobject_two)
      end
    end

    context "when read fails" do
      it "handles exceptions" do
        allow(client).to receive(:initialize_client)
        allow(client).to receive(:@client).and_return(double)
        allow(client.instance_variable_get(:@client)).to receive(:query).and_raise(StandardError.new("Read failed"))

        expect { client.read(sync_config) }.to_not raise_error
      end
    end
  end

  describe "#meta_data" do
    it "serves it github image url as icon" do
      image_url = "https://raw.githubusercontent.com/Multiwoven/multiwoven-integrations/#{client.class::MAIN_BRANCH_SHA}/lib/multiwoven/integrations/source/salesforce_consumer_goods_cloud/icon.svg"
      expect(client.send(:meta_data)[:data][:icon]).to eq(image_url)
    end
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

  private

  def sync_config
    Multiwoven::Integrations::Protocol::SyncConfig.from_json(
      sync_config_json.to_json
    )
  end
end
