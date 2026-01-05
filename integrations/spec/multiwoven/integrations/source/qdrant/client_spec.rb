# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Qdrant::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: false)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      host: "http://localhost:63333",
      api_key: "test_key",
      collection_name: "test_collection"
    }
  end
  let(:sync_config_json) do
    {
      source: {
        name: "Qdrant",
        type: "source",
        connection_specification: connection_config
      },
      limit: 1,
      vector: [0.1, 0.2, 0.3]
    }
  end

  describe "#check_connection" do
    context "when the connection is succesful" do
      before do
        stub_request(:get, connection_config[:host])
          .to_return(status: 200, body: "", headers: {})
      end

      it "returns a suceeded connection status" do
        allow(client).to receive(:create_connection) do
          client.instance_variable_set(:@host, connection_config[:host])
          client.instance_variable_set(:@api_key, connection_config[:api_key])
          client.instance_variable_set(:@collection_name, connection_config[:collection_name])
        end
        message = client.check_connection(sync_config_json[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      before do
        stub_request(:get, connection_config[:host])
          .to_return(status: 401, body: "", headers: {})
      end
      it "returns a failed connection status with an error message" do
        message = client.check_connection(sync_config_json[:source][:connection_specification])
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
        message = client.check_connection(sync_config_json[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to eq("Connection failed")
      end
    end
  end

  describe "#discover" do
    it "successfully returns the catalog message" do
      message = client.discover(nil)
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.request_rate_limit).to eql(1200)
      expect(catalog.request_rate_limit_unit).to eql("minute")
      expect(catalog.request_rate_concurrency).to eql(10)
    end

    it "handles exceptions during discovery" do
      allow(client).to receive(:read_json).and_raise(StandardError.new("test error"))
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError),
        hash_including(context: "QDRANT:DISCOVER:EXCEPTION", type: "error")
      )
      client.discover
    end
  end

  describe "#search" do
    context "when the search operation is successful" do
      let(:expected_data) do
        {
          "id" => "1",
          "payload" => { "name" => "Example" },
          "vector" => [0.1, 0.2, 0.3],
          "score" => 0.99
        }
      end

      before do
        stub_request(:post, "http://localhost:63333/collections/test_collection/points/search")
          .with(
            body: "{\"vector\":[0.1,0.2,0.3],\"top\":1}",
            headers: {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "Api-Key" => connection_config[:api_key],
              "Content-Type" => "application/json",
              "Host" => "localhost:63333",
              "User-Agent" => "Ruby"
            }
          )
          .to_return(
            status: 200,
            body: {
              result: [
                {
                  id: "1",
                  payload: { name: "Example" },
                  score: 0.99,
                  vector: [0.1, 0.2, 0.3]
                }
              ]
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "increments the success count" do
        sync_config = Multiwoven::Integrations::Protocol::VectorConfig.from_json(sync_config_json.to_json)
        allow(client).to receive(:create_connection) do
          client.instance_variable_set(:@host, connection_config[:host])
          client.instance_variable_set(:@api_key, connection_config[:api_key])
          client.instance_variable_set(:@collection_name, connection_config[:collection_name])
        end
        records = client.search(sync_config)
        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(records.first.record.data).to eq(expected_data)
      end

      it "includes filters in the request body when filters are provided" do
        sync_config_json_with_filters = sync_config_json.merge(
          filters: [
            { "field" => "status", "value" => "active" },
            { "field" => "category", "operator" => "neq", "value" => "archived" }
          ]
        )
        sync_config = Multiwoven::Integrations::Protocol::VectorConfig.from_json(sync_config_json_with_filters.to_json)

        stub_request(:post, "http://localhost:63333/collections/test_collection/points/search")
          .with(
            body: hash_including(
              "vector" => [0.1, 0.2, 0.3],
              "top" => 1,
              "filter" => hash_including(
                "must" => array_including(
                  hash_including("key" => "status", "match" => hash_including("value" => "active"))
                ),
                "must_not" => array_including(
                  hash_including("key" => "category", "match" => hash_including("value" => "archived"))
                )
              )
            ),
            headers: {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "Api-Key" => connection_config[:api_key],
              "Content-Type" => "application/json",
              "Host" => "localhost:63333",
              "User-Agent" => "Ruby"
            }
          )
          .to_return(
            status: 200,
            body: {
              result: [
                {
                  id: "1",
                  payload: { name: "Example", status: "active" },
                  score: 0.99,
                  vector: [0.1, 0.2, 0.3]
                }
              ]
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        allow(client).to receive(:create_connection) do
          client.instance_variable_set(:@host, connection_config[:host])
          client.instance_variable_set(:@api_key, connection_config[:api_key])
          client.instance_variable_set(:@collection_name, connection_config[:collection_name])
        end

        records = client.search(sync_config)
        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
      end

      it "does not include filter in request body when filters are empty" do
        sync_config_json_with_empty_filters = sync_config_json.merge(filters: [])
        sync_config = Multiwoven::Integrations::Protocol::VectorConfig.from_json(sync_config_json_with_empty_filters.to_json)

        stub_request(:post, "http://localhost:63333/collections/test_collection/points/search")
          .with(
            body: hash_excluding(:filter),
            headers: {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "Api-Key" => connection_config[:api_key],
              "Content-Type" => "application/json",
              "Host" => "localhost:63333",
              "User-Agent" => "Ruby"
            }
          )
          .to_return(
            status: 200,
            body: {
              result: [
                {
                  id: "1",
                  payload: { name: "Example" },
                  score: 0.99,
                  vector: [0.1, 0.2, 0.3]
                }
              ]
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        allow(client).to receive(:create_connection) do
          client.instance_variable_set(:@host, connection_config[:host])
          client.instance_variable_set(:@api_key, connection_config[:api_key])
          client.instance_variable_set(:@collection_name, connection_config[:collection_name])
        end

        records = client.search(sync_config)
        expect(records).to be_an(Array)
      end
    end
  end
end
