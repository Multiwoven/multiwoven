# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Qdrant::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: false)
  end

  let(:logger) { double("Logger") }
  let(:client) { described_class.new }
  let(:connection_config) do
    {
      api_url: "http://localhost:63333",
      api_key: "test_key"
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
        name: "Qdrant",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT * FROM /data.csv",
        query_type: "table_selector",
        primary_key: "id"
      },
      sync_mode: "incremental",
      destination_sync_mode: "insert",
      stream: {
        name: "collection_name",
        action: "create",
        supported_sync_modes: %w[incremental full_refresh],
        json_schema: {
          type: "object",
          required: %w[id vector payload],
          properties: {
            id: {
              type: "string"
            },
            vector: {
              type: "vector"
            },
            payload: {
              type: "object",
              properties: {
                name: {
                  type: "string"
                }
              }
            }
          }
        }
      }
    }
  end
  let(:headers) do
    {
      "Accept" => "application/json",
      "Authorization" => "Bearer #{connection_config[:api_key]}",
      "Content-Type" => "application/json",
      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "Host" => "localhost:63333",
      "User-Agent" => "Ruby"
    }
  end
  let(:collections_response) do
    {
      "result": {
        "collections": [
          {
            "name": "collection_name"
          }
        ]
      }
    }
  end
  let(:collection_details_response) do
    {
      "result": {
        "payload_schema": {
          "a_integer": {
            "data_type": "integer"
          },
          "a_float": {
            "data_type": "float"
          },
          "a_bool": {
            "data_type": "bool"
          },
          "a_keyword": {
            "data_type": "keyword"
          },
          "a_geo": {
            "data_type": "geo"
          },
          "a_datetime": {
            "data_type": "datetime"
          },
          "a_uuid": {
            "data_type": "uuid"
          }
        }
      }
    }
  end

  let(:collection_details_without_payload_schema_response) do
    {
      "result": {
        "payload_schema": {}
      }
    }
  end

  let(:collections_points_response) do
    {
      "result": {
        "message": "bad request"
      }
    }
  end

  describe "#check_connection" do
    context "when the connection is succesful" do
      before do
        stub_request(:get, connection_config[:api_url])
          .to_return(status: 200, body: "", headers: {})
      end

      it "returns a suceeded connection status" do
        allow(client).to receive(:create_connection)
        message = client.check_connection(sync_config_json[:destination][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      before do
        stub_request(:get, connection_config[:api_url])
          .to_return(status: 401, body: "", headers: {})
      end
      it "returns a failed connection status with an error message" do
        message = client.check_connection(sync_config_json[:destination][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("failed")
      end
    end

    context "when an exception occurs" do
      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .and_raise(StandardError.new("Connection failed"))
      end
      it "handles exception and returns a failed connection status with an error message" do
        message = client.check_connection(sync_config_json[:destination][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to eq("Connection failed")
      end
    end
  end

  describe "#discover" do
    context "when discovers schema successfully" do
      before do
        stub_request(:get, "#{connection_config[:api_url]}/collections")
          .with(headers: headers)
          .to_return(status: 200, body: collections_response.to_json)
        collection_name = collections_response[:result][:collections].first[:name]
        stub_request(:get, "#{connection_config[:api_url]}/collections/#{collection_name}")
          .to_return(status: 200, body: collection_details_response.to_json)
      end
      it "returns schema with payload schema" do
        message = client.discover(connection_config)
        expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)

        first_stream = message.catalog.streams.first
        expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
        expect(first_stream.name).to eq("collection_name")
        expect(first_stream.json_schema).to be_an(Hash)
        expect(first_stream.json_schema["type"]).to eq("object")
        expect(first_stream.json_schema["properties"]).to be_an(Hash)

        properties = first_stream.json_schema["properties"]
        expect(properties["id"]).to be_an(Hash)
        expect(properties["id"]["type"]).to eq("string")
        expect(properties["vector"]).to be_an(Hash)
        expect(properties["vector"]["type"]).to eq("vector")
        expect(properties["payload"]).to be_an(Hash)

        payload = first_stream.json_schema["properties"]["payload"]
        expect(payload["type"]).to eq("object")

        expect(payload["properties"]).to be_an(Hash)
        expect(payload["properties"]["a_integer"]["type"]).to eq("integer")
        expect(payload["properties"]["a_float"]["type"]).to eq("number")
        expect(payload["properties"]["a_bool"]["type"]).to eq("boolean")
        expect(payload["properties"]["a_keyword"]["type"]).to eq("string")
        expect(payload["properties"]["a_datetime"]["type"]).to eq("string")

        geo_attribute = payload["properties"]["a_geo"]
        expect(geo_attribute["type"]).to eq("object")
        expect(geo_attribute["properties"]).to be_an(Hash)
        expect(geo_attribute["properties"]["lat"]).to be_an(Hash)
        expect(geo_attribute["properties"]["lat"]["type"]).to eq("number")
        expect(geo_attribute["properties"]["lon"]).to be_an(Hash)
        expect(geo_attribute["properties"]["lon"]["type"]).to eq("number")
      end
    end

    context "when discovers schema successfully without payload schema" do
      before do
        stub_request(:get, "#{connection_config[:api_url]}/collections")
          .with(headers: headers)
          .to_return(status: 200, body: collections_response.to_json)
        collection_name = collections_response[:result][:collections].first[:name]
        stub_request(:get, "#{connection_config[:api_url]}/collections/#{collection_name}")
          .to_return(status: 200, body: collection_details_without_payload_schema_response.to_json)
      end
      it "returns schema with payload schema" do
        message = client.discover(connection_config)
        expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)

        first_stream = message.catalog.streams.first
        expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
        expect(first_stream.name).to eq("collection_name")
        expect(first_stream.json_schema).to be_an(Hash)
        expect(first_stream.json_schema["type"]).to eq("object")
        expect(first_stream.json_schema["properties"]).to be_an(Hash)

        properties = first_stream.json_schema["properties"]
        expect(properties["id"]).to be_an(Hash)
        expect(properties["id"]["type"]).to eq("string")
        expect(properties["vector"]).to be_an(Hash)
        expect(properties["vector"]["type"]).to eq("vector")
        expect(properties["payload"]).to be_an(Hash)

        payload = first_stream.json_schema["properties"]["payload"]
        expect(payload["type"]).to eq("object")
        expect(payload["properties"]).to be_empty
      end
    end

    context "when an exception occurs" do
      before do
        stub_request(:get, "#{connection_config[:api_url]}/collections")
          .to_return(status: 401)
      end
      it "handles exception" do
        message = client.discover(connection_config)
        expect(message).to be_an(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(message.log.name).to eq("QDRANT:DISCOVER:EXCEPTION")
      end
    end
  end

  describe "#write" do
    context "when the write operation is successful" do
      before do
        collection_name = collections_response[:result][:collections].first[:name]
        stub_request(:put, "#{connection_config[:api_url]}/collections/#{collection_name}/points")
          .to_return(status: 200, body: { "status" => "ok" }.to_json)
      end
      it "increments the success count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
        records = [{ "id" => 1, "vector" => "[1,1,1]", "payload" => { "name" => "data" } }]

        message = client.write(sync_config, records)
        tracker = message.tracking

        expect(tracker.success).to eq(records.count)
        expect(tracker.failed).to eq(0)

        log_message = message.tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("info")
        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end
    end

    context "when the write operation is not successful" do
      before do
        collection_name = collections_response[:result][:collections].first[:name]
        stub_request(:put, "#{connection_config[:api_url]}/collections/#{collection_name}/points")
          .to_return(status: 400, body: collections_points_response.to_json)
      end
      it "increments the success count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
        records = [{ "id" => 1, "vector" => "[1,1,1]", "payload" => { "name" => "data" } }]

        message = client.write(sync_config, records)
        tracker = message.tracking

        expect(tracker.success).to eq(0)
        expect(tracker.failed).to eq(records.count)

        log_message = message.tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("error")
        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end
    end

    context "when the write operation throws an exception" do
      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .and_raise(StandardError.new("Write failed"))
      end
      it "handles the exception" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
        records = [{ "id" => 1, "vector" => "[1,1,1]", "payload" => { "name" => "data" } }]

        message = client.write(sync_config, records)
        tracker = message.tracking

        expect(tracker.success).to eq(0)
        expect(tracker.failed).to eq(records.count)

        log_message = message.tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("error")
        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
        message = JSON.parse(log_message.message)
        expect(message["response"]).to eq("Write failed")
      end
    end
  end
end
