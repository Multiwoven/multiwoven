# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::MicrosoftDynamics::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:access_token) { "test-access-token" }
  let(:connection_config) do
    {
      instance_url: "testing-instance",
      tenant_id: "tenant-id",
      application_id: "application-id",
      client_secret: "client-secret"
    }
  end
  let(:auth_headers) do
    {
      "Accept" => "application/json",
      "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/json"
    }
  end
  let(:token_url) { "https://login.microsoftonline.com/tenant-id/oauth2/v2.0/token" }
  let(:whoami_url) { "https://testing-instance.crm.dynamics.com/api/data/v9.2/WhoAmI" }
  let(:accounts_url) { "https://testing-instance.crm.dynamics.com/api/data/v9.2/accounts" }
  let(:accounts_select_url) do
    "#{accounts_url}?$select=accountid,name&$orderby=accountid&$top=5000"
  end
  let(:entity_order_by) do
    {
      "accounts" => "accountid",
      "contacts" => "contactid",
      "opportunities" => "opportunityid",
      "leads" => "leadid"
    }
  end
  let(:sync_config_json) do
    {
      source: {
        name: "Microsoft Dynamics",
        type: "source",
        connection_specification: connection_config
      },
      destination: {
        name: "Sample Destination Connector",
        type: "destination",
        connection_specification: {
          example_destination_key: "example_destination_value"
        }
      },
      model: {
        name: "Accounts",
        query: "SELECT accountid, name FROM accounts",
        query_type: "raw_sql",
        primary_key: "accountid"
      },
      stream: {
        name: "accounts",
        action: "create",
        json_schema: { "accountid" => "string", "name" => "string" },
        supported_sync_modes: %w[incremental]
      },
      sync_mode: "incremental",
      destination_sync_mode: "insert",
      sync_id: "1",
      sync_run_id: "1"
    }
  end
  let(:sync_config) { Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json) }
  let(:connector_instance) do
    instance_double("ConnectorInstance", configuration: { "access_token" => access_token })
  end

  def stub_token_request(token: access_token)
    stub_request(:post, token_url)
      .to_return(status: 200, body: { "access_token" => token }.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        stub_token_request
        stub_request(:get, whoami_url)
          .with(headers: auth_headers)
          .to_return(status: 200, body: { "UserId" => "12345" }.to_json, headers: { "Content-Type" => "application/json" })

        message = client.check_connection(connection_config)
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        stub_request(:post, token_url).to_return(status: 400, body: { "error" => "invalid_client" }.to_json)

        message = client.check_connection(connection_config)
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("invalid_client")
      end
    end
  end

  describe "#discover" do
    it "discovers schema successfully" do
      stub_token_request
      %w[accounts contacts opportunities leads].each do |entity|
        order_by = entity_order_by[entity]
        stub_request(
          :get,
          "https://testing-instance.crm.dynamics.com/api/data/v9.2/#{entity}?$orderby=#{order_by}&$top=1"
        ).to_return(
          status: 200,
          body: {
            "value" => [
              {
                "@odata.etag" => "W/\"1\"",
                "id" => "1",
                "name" => "Sample"
              }
            ]
          }.to_json
        )
      end

      message = client.discover(connection_config)
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.streams.map(&:name)).to eq(%w[accounts contacts opportunities leads])
      first_stream = catalog.streams.first
      expect(first_stream.json_schema["properties"]).to include("id", "name")
      expect(first_stream.json_schema["properties"]).not_to have_key("@odata.etag")
    end
  end

  describe "#read" do
    it "reads records successfully" do
      allow(sync_config.source).to receive(:connector_instance).and_return(connector_instance)
      stub_request(:get, accounts_select_url)
        .with(headers: auth_headers)
        .to_return(
          status: 200,
          body: {
            "value" => [
              { "@odata.etag" => "W/\"1\"", "accountid" => "a1", "name" => "Contoso" },
              { "accountid" => "a2", "name" => "Fabrikam", "address" => { "city" => "Seattle" } }
            ]
          }.to_json
        )

      records = client.read(sync_config)
      expect(records).to be_an(Array)
      expect(records.size).to eq(2)
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
      expect(records.first.record.data).to eq({ "accountid" => "a1", "name" => "Contoso" })
      expect(records.last.record.data).to eq({ "accountid" => "a2", "name" => "Fabrikam" })
    end

    it "applies offset in-process and pages with $top/$orderby" do
      sync_config.limit = 10
      sync_config.offset = 5
      allow(sync_config.source).to receive(:connector_instance).and_return(connector_instance)
      page_records = (1..6).map { |i| { "accountid" => "a#{i}", "name" => "Account #{i}" } }
      stub_request(
        :get,
        "#{accounts_url}?$select=accountid,name&$orderby=accountid&$top=15"
      ).to_return(status: 200, body: { "value" => page_records }.to_json)

      records = client.read(sync_config)
      expect(records.size).to eq(1)
      expect(records.first.record.data["accountid"]).to eq("a6")
    end

    it "handles read failures" do
      sync_config.sync_run_id = "2"
      allow(sync_config.source).to receive(:connector_instance).and_return(nil)
      allow(client).to receive(:create_connection).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError), {
          context: "MICROSOFT:DYNAMICS:READ:EXCEPTION",
          type: "error",
          sync_id: "1",
          sync_run_id: "2"
        }
      )
      client.read(sync_config)
    end
  end

  describe "access token persistence" do
    it "uses a stored access token from connector_instance configuration" do
      allow(sync_config.source).to receive(:connector_instance).and_return(connector_instance)
      expect(client).not_to receive(:refresh_access_token)
      stub_request(:get, accounts_select_url)
        .to_return(status: 200, body: { "value" => [] }.to_json)

      client.read(sync_config)
    end

    it "persists a refreshed access token on connector_instance" do
      instance = instance_double("ConnectorInstance", configuration: {})
      allow(sync_config.source).to receive(:connector_instance).and_return(instance)
      stub_token_request(token: "fresh-token")
      expect(instance).to receive(:update!).with(configuration: { "access_token" => "fresh-token" })
      stub_request(:get, accounts_select_url)
        .with(headers: {
                "Accept" => "application/json",
                "Authorization" => "Bearer fresh-token",
                "Content-Type" => "application/json"
              })
        .to_return(status: 200, body: { "value" => [] }.to_json)

      client.read(sync_config)
    end

    it "refreshes the access token when Dynamics returns an expired token error" do
      allow(sync_config.source).to receive(:connector_instance).and_return(connector_instance)
      expired_body = {
        "error" => {
          "code" => "InvalidAuthenticationToken",
          "message" => "Access token has expired."
        }
      }.to_json

      stub_request(:get, accounts_select_url)
        .with(headers: auth_headers)
        .to_return(status: 401, body: expired_body)
      stub_token_request(token: "refreshed-token")
      stub_request(:get, accounts_select_url)
        .with(headers: {
                "Accept" => "application/json",
                "Authorization" => "Bearer refreshed-token",
                "Content-Type" => "application/json"
              })
        .to_return(status: 200, body: { "value" => [{ "accountid" => "a1", "name" => "Contoso" }] }.to_json)

      expect(connector_instance).to receive(:update!).with(configuration: { "access_token" => "refreshed-token" })

      records = client.read(sync_config)
      expect(records.first.record.data["accountid"]).to eq("a1")
    end
  end

  describe "#meta_data" do
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
