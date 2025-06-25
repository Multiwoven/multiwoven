# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::PineconeDB::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      region: "us-east-1",
      api_key: "test_key",
      index_name: "test",
      namespace: "test_vectors"
    }
  end
  let(:sync_config_json) do
    {
      source: {
        name: "PineconeDB",
        type: "source",
        connection_specification: connection_config
      },
      vector: [0.1, 0.2, 0.3],
      limit: 1
    }
  end

  let(:pinecone_client) { double("Pinecone::Client") }
  let(:pinecone_index) { double("Pinecone::Index") }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(client).to receive(:create_connection).and_return(pinecone_client)
        allow(pinecone_client).to receive(:describe_index).and_return(double("response", code: 200))

        client.instance_variable_set(:@index_name, "test")

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

  describe "#discover" do
    it "successfully returns the catalog message" do
      message = client.discover(nil)
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.request_rate_limit).to eql(120_000)
      expect(catalog.request_rate_limit_unit).to eql("minute")
      expect(catalog.request_rate_concurrency).to eql(10)
    end

    it "handles exceptions during discovery" do
      allow(client).to receive(:read_json).and_raise(StandardError.new("test error"))
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError),
        hash_including(context: "PINECONE:DISCOVER:EXCEPTION", type: "error")
      )
      client.discover
    end
  end

  describe "#search" do
    context "when the search operation is successful" do
      it "increments the success count" do
        sync_config = Multiwoven::Integrations::Protocol::VectorConfig.from_json(sync_config_json.to_json)
        response_body = {
          "matches" => [
            {
              "id" => "400",
              "values" => [0.1, 0.2, 0.3],
              "metadata" => { "source" => "test" }
            }
          ]
        }.to_json

        expected_data = {
          "id" => "400",
          "metadata" => { "source" => "test" },
          "values" => [0.1, 0.2, 0.3]
        }

        mock_response = double("PineconeResponse", body: response_body)

        allow(client).to receive(:create_connection).and_return(pinecone_client)
        allow(pinecone_client).to receive(:index).with("test").and_return(pinecone_index)
        allow(pinecone_index).to receive(:query).and_return(mock_response)

        client.instance_variable_set(:@index_name, "test")
        client.instance_variable_set(:@namespace, "test_vectors")
        client.instance_variable_set(:@api_key, "test_key")
        client.instance_variable_set(:@region, "us-east-1")

        records = client.search(sync_config)
        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(records.first.record.data).to eq(expected_data)
      end
    end

    context "when the search operation fails" do
      it "increments the failure count" do
        s_config = Multiwoven::Integrations::Protocol::VectorConfig.from_json(sync_config_json.to_json)

        allow(Pinecone::Client).to receive(:new).and_return(pinecone_client)
        allow(pinecone_client).to receive(:index).with("test").and_raise(StandardError.new("an instance of StandardError"))

        client.instance_variable_set(:@pinecone, pinecone_client)
        client.instance_variable_set(:@namespace, "test_vectors")
        client.instance_variable_set(:@index_name, "test")
        client.instance_variable_set(:@api_key, "test_key")
        client.instance_variable_set(:@region, "us-east-1")

        expect(client).to receive(:handle_exception).with(
          an_instance_of(StandardError), {
            context: "PINECONE:SEARCH:EXCEPTION",
            type: "error"
          }
        )
        client.search(s_config)
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
