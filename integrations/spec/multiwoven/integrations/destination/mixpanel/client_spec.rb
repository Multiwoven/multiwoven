# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Mixpanel::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:api_token) { "api_token" }
  let(:base_url) { "https://api.mixpanel.com" }
  let(:connection_config) do
    {
      api_token: api_token
    }
  end

  let(:mixpanel_user_profile_json_schema) do
    catalog = client.discover.catalog
    catalog.streams.find { |stream| stream.name == "UserProfiles" }.json_schema
  end

  let(:mixpanel_event_json_schema) do
    catalog = client.discover.catalog
    catalog.streams.find { |stream| stream.name == "Events" }.json_schema
  end

  let(:sync_config_json) do
    {
      source: {
        name: "SourceConnectorName",
        type: "source",
        connection_specification: {
          private_api_key: "test_api_key"
        }
      },
      destination: {
        name: "Mixpanel",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT * FROM USERS LIMIT 1",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "UserProfiles",
        action: "create",
        request_rate_limit: 5,
        rate_limit_unit_seconds: 1,
        json_schema: mixpanel_user_profile_json_schema
      },
      sync_mode: "incremental",
      cursor_field: "timestamp",
      destination_sync_mode: "insert"
    }.with_indifferent_access
  end

  let(:records) do
    [
      { id: "123", name: "All Events", properties: { name: "John Doe", email: "john@example.com" } }
    ]
  end

  let(:profile_body) do
    [
      {
        "$token" => "api_token",
        "$distinct_id" => "123",
        "$set" => {
          "name" => "John Doe",
          "email" => "john@example.com"
        }
      }
    ].to_json
  end

  describe "#check_connection" do
  context 'when connection is valid' do
    before do
      stub_request(:post, "#{base_url}/track")
        .to_return(status: 200, body: { status: 1 }.to_json)
    end

    it 'returns a success status' do
      result = subject.check_connection(connection_config)
      expect(result.type).to eq('connection_status')
      expect(result.connection_status.status).to eq('succeeded')
    end
    
  end

  context 'when the connection fails' do
      before do
        stub_request(:post, "https://api.mixpanel.com/track")
          .to_return(status: 401, body: 'Unauthorized')
      end

      it 'returns a failed connection status with an error message' do
        result = subject.check_connection(connection_config)
        expect(result.type).to eq('connection_status')
        expect(result.connection_status.status).to eq('failed')
        expect(result.connection_status.message).to eq('Authentication Error: Invalid API token.')
      end
  end
  end

  describe "#write" do
  context "when writing user profiles" do
    let(:endpoint) { "#{base_url}/engage" }
    
    before do
      stub_request(:post, endpoint)
        .with(
          body: profile_body,
          headers: {
            "Accept" => "text/plain",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Content-Type" => "application/json",
            "Host" => "api.mixpanel.com",
            "User-Agent" => "Ruby"
          }
        )
        .to_return(status: 200, body: '{"status": "ok"}', headers: {})
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
  
  end

  describe "#meta_data" do
    it "serves its GitHub image URL as an icon" do
      image_url = "https://raw.githubusercontent.com/Multiwoven/multiwoven/main/integrations/lib/multiwoven/integrations/destination/mixpanel/icon.svg"
      expect(client.send(:meta_data)[:data][:icon]).to eq(image_url)
    end
  end

  private

  def sync_config
    Multiwoven::Integrations::Protocol::SyncConfig.from_json(
      sync_config_json.to_json
    )
  end

  describe "#discover" do
    it "returns a catalog" do
      message = client.discover
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      catalog.streams.each do |stream|
        case stream.name
        when "UserProfiles"
          expect(stream.supported_sync_modes).to eql(["full_refresh", "incremental"])
        when "Events"
          expect(stream.supported_sync_modes).to eql(["full_refresh", "incremental"])
        end
      end
    end
  end
end
