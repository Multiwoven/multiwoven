# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Http::Client do # rubocop:disable Metrics/BlockLength
    include WebMock::API
  
    before(:each) do
      WebMock.disable_net_connect!(allow_localhost: true)
    end
  
    let(:client) { described_class.new }
    let(:mock_http_session) { double("Net::Http::Session") }
    let(:mock_http_file) { double("Net::Http::Operations::File") }
    let(:connection_config) do
      {
        destination_url: "test_url",
        api_key: "test_key",
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
        destination_sync_mode: "insert" }.with_indifferent_access
    end
  
    let(:records) do
      [
        { "id" => 1, "name" => "Test Record" }
      ]
    end
    let(:csv_content) { "id,name\n1,Test Record\n" }
  
    describe "#check_connection" do
      it "successfully checks connection" do
        expect(client).to receive(:with_http_client).and_yield(double)
        expect(client).to receive(:test_file_operations)
        response = client.check_connection(connection_config)
        expect(response.connection_status.status).to eq("succeeded")
      end
  
      it "handles connection failure" do
        allow(client).to receive(:with_http_client).and_raise(StandardError.new("connection failed"))
        response = client.check_connection(connection_config)
        expect(response.connection_status.status).to eq("failed")
        expect(response.connection_status.message).to eq("connection failed")
      end
    end
  
    describe "#discover" do
      it "returns a catalog" do
        message = client.discover(connection_config)
        catalog = message.catalog
        expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
        expect(catalog.request_rate_limit).to eql(600)
        expect(catalog.request_rate_limit_unit).to eql("minute")
        expect(catalog.request_rate_concurrency).to eql(10)
        expect(catalog.streams.count).to eql(1)
        expect(catalog.schema_mode).to eql("schemaless")
        expect(catalog.streams[0].name).to eql("sftp")
        expect(catalog.streams[0].batch_support).to eql(true)
        expect(catalog.streams[0].batch_size).to eql(100_000)
        expect(catalog.streams[0].supported_sync_modes).to eql(%w[full_refresh incremental])
      end
    end
  
    describe "#write" do
    let(:success_response) { instance_double("Response", success?: true, body: "{\"data\": []}", code: 200) }
    let(:failure_response) { instance_double("Response", success?: false, body: "{\"error\": \"error_message\"}", code: 400) }

    it "increments the success count" do
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).and_return(success_response)
      sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
      message = client.write(sync_config, records)
      expect(message.tracking.success).to eq(2)
      expect(message.tracking.failed).to eq(0)
    end

    it "increments the failure count" do
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).and_return(failure_response)
      sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
      message = client.write(sync_config, records)
      expect(message.tracking.success).to eq(0)
      expect(message.tracking.failed).to eq(2)
    end
  end
  
    # describe "#meta_data" do
    #   it "serves it github image url as icon" do
    #     image_url = "https://raw.githubusercontent.com/Multiwoven/multiwoven/main/integrations/lib/multiwoven/integrations/destination/sftp/icon.svg"
    #     expect(client.send(:meta_data)[:data][:icon]).to eq(image_url)
    #   end
    # end
  
    def sync_config
      Multiwoven::Integrations::Protocol::SyncConfig.from_json(
        sync_config_json.to_json
      )
    end
  end
  