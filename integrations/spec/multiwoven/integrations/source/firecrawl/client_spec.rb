# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Firecrawl::Client do
  let(:client) { Multiwoven::Integrations::Source::Firecrawl::Client.new }
  let(:sync_config_json) do
    {
      source: {
        name: "Firecrawl",
        type: "source",
        connection_specification: {
          base_url: "https://doc_test.com",
          api_key: "test_key"
        }
      },
      destination: {
        name: "Sample Destination Connector",
        type: "destination",
        connection_specification: {
          example_destination_key: "example_destination_value"
        }
      },
      model: {
        name: "Firecrawl",
        query: "SELECT path FROM pages WHERE path IN ('/test/paths/');",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "example_stream",
        action: "create",
        json_schema: { "field1": "type1" },
        supported_sync_modes: %w[full_refresh incremental],
        source_defined_cursor: true,
        default_cursor_field: ["field1"],
        source_defined_primary_key: [["field1"], ["field2"]],
        namespace: "exampleNamespace",
        url: "https://api.example.com/data",
        method: "GET"
      },
      sync_mode: "full_refresh",
      cursor_field: "timestamp",
      destination_sync_mode: "upsert",
      sync_id: "1"
    }
  end

  let(:sync_config) { Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json) }
  before do
    allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
  end
  let(:headers) do
    {
      "Accept" => "application/json",
      "Authorization" => "Bearer #{sync_config_json[:source][:connection_specification][:api_key]}",
      "Content-Type" => "application/json"
    }
  end

  let(:crawl_active_endpoint) { "https://api.firecrawl.dev/v1/crawl/active" }
  let(:crawl_endpoint) { "https://api.firecrawl.dev/v1/crawl" }
  let(:get_crawl_endpoint) { "https://api.firecrawl.dev/v1/crawl/123" }
  let(:scrape_endpoint) { "https://api.firecrawl.dev/v1/scrape" }

  describe "#check_connection" do
    context "when the connection is successful" do
      let(:response_body) { { "status" => "ok" }.to_json }
      before do
        response = instance_double(Net::HTTPSuccess, code: "200", body: response_body)
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(crawl_active_endpoint,
                "GET",
                payload: {},
                headers: headers,
                config: {})
          .and_return(response)
      end

      it "returns a succeeded connection status" do
        message = client.check_connection(sync_config_json[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(client).to receive(:create_connection).and_raise(StandardError, "Connection failed")
        message = client.check_connection(sync_config_json[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  describe "#read" do
    context "when the read is successful" do
      let(:data_config) do
        {
          "url": sync_config_json[:source][:connection_specification][:base_url]
        }.to_json
      end

      before do
        response = instance_double(Net::HTTPSuccess, code: "200", body: { "url" => get_crawl_endpoint }.to_json)
        crawl_result_response = instance_double(Net::HTTPSuccess, code: "200", body: {
          "status" => "complete",
          "data" => [
            { "markdown" => "# Hello", "metadata" => { "title" => "Test Page" } }
          ]
        }.to_json)
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(crawl_endpoint,
                "POST",
                payload: JSON.parse(data_config),
                headers: headers,
                config: {})
          .and_return(response)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(get_crawl_endpoint,
                "GET",
                payload: {},
                headers: headers,
                config: {})
          .and_return(crawl_result_response)
      end

      it "reads records successfully" do
        records = client.read(sync_config)
        expect(records).to be_an(Array)
        expect(records).not_to be_empty
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
      end
    end

    context "when the read fails" do
      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .and_raise(StandardError.new("Simulated crawl failure"))
      end

      it "read records failure" do
        sync_config.sync_run_id = "2"
        client.read(sync_config)
      end
    end
  end

  describe "#discover" do
    before do
      response = instance_double(Net::HTTPSuccess, code: "200", body:
      {
        "success" => true,
        "data" =>
          {
            "markdown" => "[AI Squared home page](https://docs.squared.ai)",
            "metadata" => {
              "title" => "Welcome - AI Squared",
              "og:url" => "https://docs.squared.ai/home/welcome",
              "language" => "en",
              "url" => "Test.com"
            }.to_json
          }
      }.to_json)
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
        .with(
          scrape_endpoint,
          "POST",
          payload: { "url" => sync_config_json[:source][:connection_specification][:base_url] },
          headers: headers,
          config: {}
        ).and_return(response)
    end
    it "discovers schema successfully" do
      message = client.discover(sync_config[:source][:connection_specification])
      expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
      first_stream = message.catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq("scrape")
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "metadata" => { "type" => "string" }, "markdown" => { "type" => "string" }, "url" => { "type" => "string" }, "markdown_hash" => { "type" => "string" } })
    end
  end

  describe "#meta_data" do
    # change this to rollout validation for all connector rolling out
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
