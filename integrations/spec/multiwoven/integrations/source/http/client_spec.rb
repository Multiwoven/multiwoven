# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Http::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:mock_http_session) { double("Net::Http::Session") }

  let(:payload) do
    {
      queries: "Hello there"
    }
  end

  let(:sync_config_json) do
    {
      source: {
        name: "DestinationConnectorName",
        type: "destination",
        connection_specification: {
          base_url: "http://localhost:3000",
          path: "/api/v1/syncs/116/sync_runs/287/sync_records",
          headers: {
            "Workspace-Id" => 5,
            "Authorization" => "Bearer Test"
          },
          request_format: "{}",
          sample_query: "",
          http_method: "GET",
          parse_response: "$.data[*].attributes.record",
          config: { timeout: 30 },
          params: { status: "success" },
          offset_param: "page",
          limit_param: "per_page"
        }
      },
      destination: {
        name: "Http",
        type: "destination",
        connection_specification: {
          example_destination_key: "example_destination_value"
        }
      },
      model: {
        name: "ExampleModel",
        query: payload.to_json,
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "example_stream",
        json_schema: { "field1": "type1" },
        request_method: "POST",
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1
      },
      sync_mode: "full_refresh",
      cursor_field: "timestamp",
      destination_sync_mode: "upsert",
      sync_id: "1",
      increment_strategy_config: Multiwoven::Integrations::Protocol::IncrementStrategyConfig.new(increment_strategy: "page")
    }
  end

  let(:sync_config) { Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json) }
  before do
    allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      let(:response_body) { { "message" => "success" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "200", "Unauthorized")
        response.content_type = "application/json"
        url = sync_config_json[:source][:connection_specification][:base_url] + sync_config_json[:source][:connection_specification][:path]
        http_method = sync_config_json[:source][:connection_specification][:http_method]
        headers = sync_config_json[:source][:connection_specification][:headers]
        config = sync_config_json[:source][:connection_specification][:config]
        request_format = sync_config_json[:source][:connection_specification][:request_format]
        params = { status: "success" }
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(url,
                http_method,
                payload: JSON.parse(request_format),
                headers: headers,
                options: { config: config, params: params })
          .and_return(response)
      end

      it "returns a successful connection status" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        response = client.check_connection(s_config[:source][:connection_specification])
        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("succeeded")
      end
    end

    context "when the connection fails" do
      let(:response_body) { { "message" => "failed" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "401", "Unauthorized")
        response.content_type = "application/json"
        url = sync_config_json[:source][:connection_specification][:url_host]
        http_method = sync_config_json[:source][:connection_specification][:http_method]
        headers = sync_config_json[:source][:connection_specification][:headers]
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(url,
                http_method,
                headers: headers)
          .and_return(response)
      end

      it "returns a failed connection status with an error message" do
        response = client.check_connection(sync_config_json[:source][:connection_specification])

        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("failed")
      end
    end
  end

  describe "#discover" do
    let(:response_body) do
      {
        "data" => [
          {
            "id" => "10854187",
            "type" => "sync_records",
            "attributes" => {
              "sync_id" => 565,
              "sync_run_id" => 451,
              "record" => { "col1" => 2, "col2" => "Second", "col3" => 2.2 },
              "status" => "success",
              "action" => "destination_insert"
            }
          },
          {
            "id" => "10854189",
            "type" => "sync_records",
            "attributes" => {
              "sync_id" => 565,
              "sync_run_id" => 451,
              "record" => { "col1" => 4, "col2" => "Fourth", "col3" => 4.4 },
              "status" => "success",
              "action" => "destination_insert"
            }
          },
          {
            "id" => "10854188",
            "type" => "sync_records",
            "attributes" => {
              "sync_id" => 565,
              "sync_run_id" => 451,
              "record" => { "col1" => 5, "col2" => "Fifth", "col3" => 5.5 },
              "status" => "success",
              "action" => "destination_insert"
            }
          }
        ],
        "links" => [{
          "self" => "http://localhost:3000/api/v1/syncs/565/sync_runs/451573/sync_records?page=1",
          "next" => "http://localhost:3000/api/v1/syncs/565/sync_runs/451573/sync_records?page=2",
          "last" => "http://localhost:3000/api/v1/syncs/565/sync_runs/451573/sync_records?page=3"
        }]
      }.to_json
    end

    before do
      response = Net::HTTPSuccess.new("1.1", "200", "Authorized")
      response.content_type = "application/json"
      url = sync_config_json[:source][:connection_specification][:base_url] + sync_config_json[:source][:connection_specification][:path]
      http_method = sync_config_json[:source][:connection_specification][:http_method]
      headers = sync_config_json[:source][:connection_specification][:headers]
      request_format = sync_config_json[:source][:connection_specification][:request_format]
      config = sync_config_json[:source][:connection_specification][:config]
      params = { status: "success" }
      allow(response).to receive(:body).and_return(response_body)
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
        .with(url,
              http_method,
              payload: JSON.parse(request_format),
              headers: headers,
              options: { config: config, params: params })
        .and_return(response)
    end

    it "successfully returns the catalog message" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      message = client.discover(s_config[:source][:connection_specification])
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.request_rate_limit).to eql(60)
      expect(catalog.request_rate_limit_unit).to eql("minute")
      expect(catalog.request_rate_concurrency).to eql(10)
      first_stream = catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq("data")
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq(
        {
          "data" => {
            "type" => "array",
            "items" => {
              "type" => "object",
              "properties" => {
                "attributes" => {
                  "type" => "object",
                  "properties" => {
                    "action" => { "type" => %w[string null] },
                    "record" => {
                      "type" => "object",
                      "properties" => {
                        "col1" => { "type" => %w[string null] },
                        "col2" => { "type" => %w[string null] },
                        "col3" => { "type" => %w[string null] }
                      }
                    },
                    "status" => { "type" => %w[string null] },
                    "sync_id" => { "type" => %w[string null] },
                    "sync_run_id" => { "type" => %w[string null] }
                  }
                },
                "id" => { "type" => %w[string null] },
                "type" => { "type" => %w[string null] }
              }
            }
          }
        }
      )
      last_stream = catalog.streams.last
      expect(last_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(last_stream.name).to eq("links")
      expect(last_stream.json_schema).to be_an(Hash)
      expect(last_stream.json_schema["type"]).to eq("object")
      expect(last_stream.json_schema["properties"]).to eq(
        {
          "links" => {
            "type" => "array",
            "items" => {
              "type" => "object",
              "properties" => {
                "last" => { "type" => %w[string null] },
                "next" => { "type" => %w[string null] },
                "self" => { "type" => %w[string null] }
              }
            }
          }
        }
      )
    end

    it "handles exceptions during discovery" do
      allow(client).to receive(:create_streams).and_raise(StandardError.new("test error"))
      client.discover(sync_config_json[:source][:connection_specification])
    end
  end

  describe "#read" do
    context "when the read is successful" do
      let(:response_body) do
        {
          "data" => [
            { "id" => "1", "type" => "sync_records", "attributes" => { "record" => { "col1" => 1 } } },
            { "id" => "2", "type" => "sync_records", "attributes" => { "record" => { "col1" => 2 } } },
            { "id" => "3", "type" => "sync_records", "attributes" => { "record" => { "col1" => 3 } } }
          ]
        }.to_json
      end

      before do
        response = Net::HTTPSuccess.new("1.1", "200", "Authorized")
        response.content_type = "application/json"
        url = sync_config_json[:source][:connection_specification][:base_url] + sync_config_json[:source][:connection_specification][:path]
        http_method = sync_config_json[:source][:connection_specification][:http_method]
        headers = sync_config_json[:source][:connection_specification][:headers]
        request_format = sync_config_json[:source][:connection_specification][:request_format]
        config = sync_config_json[:source][:connection_specification][:config]
        params = { status: "success", page: 1, per_page: 10 }
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(url,
                http_method,
                payload: JSON.parse(request_format),
                headers: headers,
                options: { config: config, params: params })
          .and_return(response)
      end

      it "successfully reads records" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        s_config.increment_strategy_config.offset = 1
        s_config.increment_strategy_config.limit = 10
        records = client.read(s_config)
        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(records.first.record.data).to eq({ "col1" => 1 })
      end
    end

    context "when the read is successful for schema + row response" do
      let(:response_body) do
        {
          "schema": {
            "fields": [
              { "name": "ID", "type": "INTEGER", "mode": "NULLABLE" },
              { "name": "Email", "type": "STRING", "mode": "NULLABLE" },
              { "name": "FirstName", "type": "STRING", "mode": "NULLABLE" },
              { "name": "LastName", "type": "STRING", "mode": "NULLABLE" }
            ]
          },
          "rows": [
            { "f": [{ "v": "1" }, { "v": "alice@example.com" }, { "v": "Alice" }, { "v": "Smith" }] },
            { "f": [{ "v": "2" }, { "v": "bob@example.com" }, { "v": "Bob" }, { "v": "Johnson" }] },
            { "f": [{ "v": "3" }, { "v": "carol@example.com" }, { "v": "Carol" }, { "v": "Williams" }] }
          ],
          "totalRows": "3",
          "jobComplete": true,
          "totalBytesProcessed": "0"
        }.to_json
      end

      before do
        response = Net::HTTPSuccess.new("1.1", "200", "Authorized")
        response.content_type = "application/json"
        url = sync_config_json[:source][:connection_specification][:base_url] + sync_config_json[:source][:connection_specification][:path]
        http_method = sync_config_json[:source][:connection_specification][:http_method]
        headers = sync_config_json[:source][:connection_specification][:headers]
        request_format = sync_config_json[:source][:connection_specification][:request_format]
        config = sync_config_json[:source][:connection_specification][:config]
        params = { status: "success", page: 1, per_page: 10 }
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(url,
                http_method,
                payload: JSON.parse(request_format),
                headers: headers,
                options: { config: config, params: params })
          .and_return(response)
      end

      it "successfully reads records" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        s_config.increment_strategy_config.offset = 1
        s_config.increment_strategy_config.limit = 10
        s_config[:source][:connection_specification][:parse_response] = "[\"$.schema.fields[*].name\", \"$.rows[*].f[*].v\"]"
        records = client.read(s_config)
        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(records.first.record.data).to eq(
          {
            "Email" => "alice@example.com",
            "FirstName" => "Alice",
            "ID" => "1",
            "LastName" => "Smith"
          }
        )
      end
    end

    context "when the read operation fails" do
      let(:response_body) { { "message" => "failed" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "401", "Unauthorized")
        response.content_type = "application/json"
        url = sync_config_json[:source][:connection_specification][:url_host]
        http_method = sync_config_json[:source][:connection_specification][:http_method]
        request_format = sync_config_json[:source][:connection_specification][:request_format]
        headers = sync_config_json[:source][:connection_specification][:headers]
        config = sync_config_json[:source][:connection_specification][:config]
        params = { status: "success", page: 1, per_page: 10 }
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(url,
                http_method,
                payload: JSON.parse(request_format),
                headers: headers,
                config: config,
                params: params)
          .and_return(response)
      end

      it "handles exceptions during reading" do
        expect(client).to receive(:handle_exception).with(
          "Failed to fetch data",
          {
            context: "HTTP:QUERY:EXCEPTION",
            type: "error"
          }
        )

        client.read(sync_config)
      end
    end
  end
end
