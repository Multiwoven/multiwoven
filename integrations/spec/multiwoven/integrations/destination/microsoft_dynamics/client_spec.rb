# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::MicrosoftDynamics::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      instance_url: "testing-instance",
      tenant_id: ENV["TENANT_ID"],
      application_id: ENV["APPLICATION_ID"],
      client_secret: ENV["CLIENT_ID"]
    }
  end
  let(:sync_config_json) do
    {
      source: {
        name: "Sample Source Connector",
        type: "source",
        connection_specification: {
          private_api_key: "test_api_key"
        }
      },
      destination: {
        name: "Microsoft Dynamics",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT col1, col2, col3 FROM test_table_1",
        query_type: "raw_sql",
        primary_key: "col1"
      },
      sync_mode: "incremental",
      destination_sync_mode: "insert",
      stream: {
        name: "contacts",
        action: "create",
        json_schema: {
          type: "object",
          properties: {
            lastname: { type: "string" },
            firstname: { type: "string" },
            emailaddress1: { type: "string", format: "email" }
          }
        },
        supported_sync_modes: %w[incremental]
      },
      sync_id: "1"
    }
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        instance_url = sync_config_json[:destination][:connection_specification][:instance_url]
        uri = URI.parse("https://#{instance_url}.crm.dynamics.com/api/data/v9.2/WhoAmI")
        stub_request(:get, uri.to_s)
          .with(
            headers: {
              "Accept" => "application/json",
              "Authorization" => "Bearer mock_access_token",
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: { "UserId" => "12345" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        allow(client).to receive(:initialize_client) do
          client.instance_variable_set(:@instance_url, "testing-instance")
        end

        allow(client).to receive(:create_access_token).and_return({ "access_token" => "mock_access_token" })
        message = client.check_connection(sync_config_json[:destination][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(client).to receive(:initialize_client)
        allow(client).to receive(:create_access_token).and_raise(StandardError, "Connection failed")
        message = client.check_connection(sync_config_json[:destination][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  describe "#discover" do
    it "discovers schema successfully" do
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
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(
          sync_config_json.to_json
        )
        instance_url = sync_config_json[:destination][:connection_specification][:instance_url]
        entity = sync_config_json[:stream][:name]
        records = [{ "lastname" => "John", "firstname" => "Doe", "emailaddress1": "john.doe@testemail.com" }]
        allow(client).to receive(:create_connection) do
          client.instance_variable_set(:@access_token, "mock_access_token")
        end
        allow(client).to receive(:build_url) do
          client.instance_variable_set(:@destination_url, "https://#{instance_url}.crm.dynamics.com/api/data/v9.2/#{entity}")
        end
        allow(client).to receive(:send_data_to_dynamics) do
          response = OpenStruct.new
          response.code = "204"
          response["location"] = "https://mock.url"
          response
        end
        response = client.write(sync_config, records, nil)
        expect(response.tracking.success).to eq(records.size)
        expect(response.tracking.failed).to eq(0)
      end
    end

    context "when the write operation fails" do
      it "increments the failure count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(
          sync_config_json.to_json
        )
        instance_url = sync_config_json[:destination][:connection_specification][:instance_url]
        entity = sync_config_json[:stream][:name]
        records = [{ "lastname" => "John", "firstname" => "Doe", "emailaddress1": "john.doe@testemail.com" }]
        allow(client).to receive(:create_connection) do
          client.instance_variable_set(:@access_token, "mock_access_token")
        end
        allow(client).to receive(:build_url) do
          client.instance_variable_set(:@destination_url, "https://#{instance_url}.crm.dynamics.com/api/data/v9.2/#{entity}")
        end
        allow(client).to receive(:send_data_to_dynamics) do
          response = OpenStruct.new
          response.code = "400"
          response.body = "Failed to send"
          response
        end
        response = client.write(sync_config, records)
        expect(response.tracking.failed).to eq(records.size)
        expect(response.tracking.success).to eq(0)
      end
    end
  end

  describe "#meta_data" do
    # change this to rollout validation for all connector rolling out
    it "client class_name and meta name is same" do
      meta_name = client.class.to_s.split("::")[-2]
      expect(client.send(:meta_data)[:data][:name]).to eq(meta_name)
    end
  end
end
