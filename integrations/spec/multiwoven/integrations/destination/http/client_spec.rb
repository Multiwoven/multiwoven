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

  describe "OAuth client_credentials" do
    let(:token_url) { "https://login.example.com/oauth2/v2.0/token" }
    let(:oauth_config) do
      {
        destination_url: "https://api.example.com/ingest",
        headers: { "X-Trace" => "abc" },
        auth_type: "oauth_client_credentials",
        token_url: token_url,
        client_id: "cid",
        client_secret: "csecret",
        scope: "https://graph.microsoft.com/.default"
      }.with_indifferent_access
    end

    # In-memory stand-in for a persisted Connector record. The client calls
    # `configuration` to read cached tokens and `update!(configuration: ...)`
    # to persist refreshed ones — no ActiveRecord needed for the unit test.
    let(:connector_instance) do
      Class.new do
        attr_accessor :configuration

        def initialize(config)
          @configuration = config
        end

        def update!(attrs)
          @configuration = attrs[:configuration]
          true
        end
      end.new(oauth_config.to_h)
    end

    def sync_config_with(config, instance: nil)
      json = sync_config_json.deep_dup
      json[:destination][:connection_specification] = config
      sc = Multiwoven::Integrations::Protocol::SyncConfig.from_json(json.to_json)
      allow(sc.destination).to receive(:connector_instance).and_return(instance) if instance
      sc
    end

    context "#check_connection" do
      it "fetches an access token and sends it as a Bearer header" do
        stub_request(:post, token_url)
          .with(body: hash_including("grant_type" => "client_credentials",
                                     "client_id" => "cid",
                                     "client_secret" => "csecret",
                                     "scope" => "https://graph.microsoft.com/.default"),
                headers: { "Content-Type" => "application/x-www-form-urlencoded" })
          .to_return(status: 200,
                     body: { access_token: "tok-1", expires_in: 3600 }.to_json,
                     headers: { "Content-Type" => "application/json" })

        stub_request(:post, "https://api.example.com/ingest")
          .with(headers: { "Authorization" => "Bearer tok-1", "X-Trace" => "abc" })
          .to_return(status: 200, body: "", headers: {})

        response = client.check_connection(oauth_config)
        expect(response.connection_status.status).to eq("succeeded")
      end

      it "returns a failed status when the token endpoint errors" do
        stub_request(:post, token_url).to_return(status: 401, body: "denied")

        response = client.check_connection(oauth_config)
        expect(response.connection_status.status).to eq("failed")
      end
    end

    context "#write with a persisted connector_instance" do
      it "reuses a cached token that is not near expiry" do
        connector_instance.configuration = connector_instance.configuration.merge(
          "oauth_access_token" => "cached-tok",
          "oauth_expires_at" => (Time.now + 3600).iso8601
        )
        sc = sync_config_with(oauth_config, instance: connector_instance)

        stub_request(:post, "https://api.example.com/ingest")
          .with(headers: { "Authorization" => "Bearer cached-tok" })
          .to_return(status: 200, body: "", headers: {})

        response = client.write(sc, records)
        expect(response.tracking.success).to eq(records.size)
        expect(WebMock).not_to have_requested(:post, token_url)
      end

      it "refreshes a token that is inside the expiry buffer and persists it" do
        connector_instance.configuration = connector_instance.configuration.merge(
          "oauth_access_token" => "stale-tok",
          "oauth_expires_at" => (Time.now + 60).iso8601 # inside 300s buffer
        )
        sc = sync_config_with(oauth_config, instance: connector_instance)

        stub_request(:post, token_url)
          .to_return(status: 200,
                     body: { access_token: "fresh-tok", expires_in: 3600 }.to_json,
                     headers: { "Content-Type" => "application/json" })
        stub_request(:post, "https://api.example.com/ingest")
          .with(headers: { "Authorization" => "Bearer fresh-tok" })
          .to_return(status: 200, body: "", headers: {})

        response = client.write(sc, records)
        expect(response.tracking.success).to eq(records.size)
        expect(WebMock).to have_requested(:post, token_url).once
        expect(connector_instance.configuration["oauth_access_token"]).to eq("fresh-tok")
        expect(Time.parse(connector_instance.configuration["oauth_expires_at"])).to be > Time.now + 3000
      end

      it "fetches a token when none has been cached yet" do
        sc = sync_config_with(oauth_config, instance: connector_instance)

        stub_request(:post, token_url)
          .to_return(status: 200,
                     body: { access_token: "first-tok", expires_in: 3600 }.to_json,
                     headers: { "Content-Type" => "application/json" })
        stub_request(:post, "https://api.example.com/ingest")
          .with(headers: { "Authorization" => "Bearer first-tok" })
          .to_return(status: 200, body: "", headers: {})

        response = client.write(sc, records)
        expect(response.tracking.success).to eq(records.size)
        expect(connector_instance.configuration["oauth_access_token"]).to eq("first-tok")
      end
    end
  end
end
