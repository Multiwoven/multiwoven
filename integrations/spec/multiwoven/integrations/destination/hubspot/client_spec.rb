# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Hubspot::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      access_token: "access_token"
    }
  end

  let(:hubspot_contacts_json_schema) do
    catalog = client.discover.catalog
    catalog.streams.find { |stream| stream.name == "contacts" }.json_schema
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
        name: "Hubspot CRM",
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
        name: "contacts",
        action: "create",
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1,
        json_schema: hubspot_contacts_json_schema
      },
      sync_mode: "full_refresh",
      cursor_field: "timestamp",
      destination_sync_mode: "insert" }.with_indifferent_access
  end

  let(:records) do
    [
      build_record("developer@multiwoven.com"),
      build_record("developer_second@multiwoven.com")
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

  describe "#discover" do
    it "returns a catalog" do
      message = client.discover
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.request_rate_limit).to eql(600)
      expect(catalog.request_rate_limit_unit).to eql("minute")
      expect(catalog.request_rate_concurrency).to eql(10)

      account_stream = catalog.streams.first
      expect(account_stream.request_rate_limit).to eql(0)
      expect(account_stream.request_rate_limit_unit).to eql("minute")
      expect(account_stream.request_rate_concurrency).to eql(0)

      catalog.streams.each do |stream|
        expect(stream.supported_sync_modes).to eql(%w[incremental])
      end
    end
  end

  describe "#write" do
    context "when the write operation is successful" do
      before do
        stub_create_request("developer@multiwoven.com", 200)
        stub_create_request("developer_second@multiwoven.com", 200)
      end

      it "increments the success count" do
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
        stub_create_request("developer@multiwoven.com", 403)
        stub_create_request("developer_second@multiwoven.com", 403)
      end

      it "increments the failure count" do
        response = client.write(sync_config, records)

        expect(response.tracking.failed).to eq(records.size)
        expect(response.tracking.success).to eq(0)
        log_message = response.tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("error")

        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end
    end
  end

  describe "#discover with custom objects" do
    let(:unique_property) { double(name: "user_uuid", type: "string", has_unique_value: true) }
    let(:other_property) { double(name: "nom_du_compte", type: "string", has_unique_value: false) }
    let(:custom_schema) do
      double(
        name: "comptes_lpl",
        object_type_id: "2-12345678",
        labels: double(singular: "Compte LPL"),
        required_properties: ["user_uuid"],
        properties: [unique_property, other_property]
      )
    end

    def stub_schemas(schemas)
      core_api = double
      allow(core_api).to receive(:get_all).and_return(double(results: schemas))
      hubspot_client = double
      allow(hubspot_client).to receive(:crm).and_return(double(schemas: double(core_api: core_api)))
      allow(::Hubspot::Client).to receive(:new).and_return(hubspot_client)
    end

    it "appends one stream per custom object carrying object type and external id in json_schema" do
      stub_schemas([custom_schema])

      catalog = client.discover(connection_config).catalog
      custom = catalog.streams.find { |stream| stream.name == "comptes_lpl" }

      expect(custom).not_to be_nil
      expect(custom.json_schema["hubspot_object_type"]).to eq("2-12345678")
      expect(custom.json_schema["external_id_property"]).to eq("user_uuid")
      expect(custom.json_schema["properties"]["properties"]["properties"]).to have_key("user_uuid")
      # standard streams are still present
      expect(catalog.streams.map(&:name)).to include("contacts")
    end

    it "still returns the standard streams when schema listing fails" do
      hubspot_client = double
      allow(hubspot_client).to receive(:crm).and_raise(StandardError.new("boom"))
      allow(::Hubspot::Client).to receive(:new).and_return(hubspot_client)

      catalog = client.discover(connection_config).catalog
      expect(catalog.streams.map(&:name)).to include("contacts")
    end
  end

  describe "#write to a custom object" do
    let(:custom_object_schema) do
      {
        "type" => "object",
        "hubspot_object_type" => "2-12345678",
        "external_id_property" => "user_uuid",
        "properties" => {
          "properties" => {
            "type" => "object",
            "properties" => { "user_uuid" => { "type" => "string" }, "nom_du_compte" => { "type" => "string" } }
          }
        }
      }
    end
    let(:custom_sync_config_json) do
      sync_config_json.merge(
        "stream" => {
          "name" => "comptes_lpl",
          "action" => "update",
          "request_rate_limit" => 4,
          "rate_limit_unit_seconds" => 1,
          "json_schema" => custom_object_schema
        }
      ).with_indifferent_access
    end
    let(:custom_sync_config) do
      Multiwoven::Integrations::Protocol::SyncConfig.from_json(custom_sync_config_json.to_json)
    end
    let(:custom_records) { [{ "properties" => { "user_uuid" => "uuid-1", "nom_du_compte" => "Alice" } }] }

    it "updates an existing record by its external id property" do
      update = stub_request(:patch, "https://api.hubapi.com/crm/v3/objects/2-12345678/uuid-1?idProperty=user_uuid")
               .to_return(status: 200, body: "{}", headers: {})

      response = client.write(custom_sync_config, custom_records)

      expect(response.tracking.success).to eq(1)
      expect(response.tracking.failed).to eq(0)
      expect(update).to have_been_requested
    end

    it "creates the record when the external id is not found (404)" do
      stub_request(:patch, "https://api.hubapi.com/crm/v3/objects/2-12345678/uuid-1?idProperty=user_uuid")
        .to_return(status: 404, body: "{}", headers: {})
      create = stub_request(:post, "https://api.hubapi.com/crm/v3/objects/2-12345678")
               .to_return(status: 201, body: "{}", headers: {})

      response = client.write(custom_sync_config, custom_records)

      expect(response.tracking.success).to eq(1)
      expect(create).to have_been_requested
    end
  end

  describe "#meta_data" do
    it "serves it github image url as icon" do
      image_url = "https://raw.githubusercontent.com/Multiwoven/multiwoven/main/integrations/lib/multiwoven/integrations/destination/hubspot/icon.svg"
      expect(client.send(:meta_data)[:data][:icon]).to eq(image_url)
    end
  end

  private

  def build_record(email)
    {
      "properties": { "email": email }
    }
  end

  def stub_create_request(email, response_code)
    stub_request(:post, "https://api.hubapi.com/crm/v3/objects/contacts")
      .with(
        body: "{\"properties\":{\"email\":\"#{email}\"}}",
        headers: {
          "Accept" => "application/json",
          "Authorization" => "Bearer access_token",
          "Content-Type" => "application/json",
          "Expect" => "",
          "User-Agent" => "hubspot-api-client-ruby; 17.2.0"
        }
      )
      .to_return(status: response_code, body: "", headers: {})
  end

  def sync_config
    Multiwoven::Integrations::Protocol::SyncConfig.from_json(
      sync_config_json.to_json
    )
  end
end
