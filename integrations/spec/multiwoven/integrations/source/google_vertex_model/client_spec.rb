# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::VertexModel::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }

  let(:payload) do
    {
      instances:
        {
          content: "Movie was good"
        }
    }
  end

  let(:sync_config_json) do
    {
      source: {
        name: "vertex-model-source",
        type: "source",
        connection_specification: {
          endpoint_id: "test-endpoint-123",
          project_id: "test-project-123",
          region: "us-central1",
          request_format: "{}",
          response_format: "{}",
          credentials_json: {
            type: "service_account",
            project_id: "test-project-123",
            private_key_id: "private_key_id-1",
            private_key: OpenSSL::PKey::RSA.new(2048),
            client_email: "test-service@test-project-123.iam.gserviceaccount.com",
            client_id: "client_id-1",
            auth_uri: "https://accounts.google.com/o/oauth2/auth",
            token_uri: "https://oauth2.googleapis.com/token",
            auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
            client_x509_cert_url: "https://www.googleapis.com/robot/v1/metadata/x509/vertex-api-service%40vertex-ai-project-433920.iam.gserviceaccount.com",
            universe_domain: "googleapis.com"
          }
        }
      },
      destination: {
        name: "DestinationConnectorName",
        type: "destination",
        connection_specification: {
          example_destination_key: "example_destination_value"
        }
      },
      model: {
        name: "ExampleModel",
        query: payload.to_json,
        query_type: "ai_ml",
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
      sync_id: "1"
    }
  end

  let(:sync_config) { Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json) }

  let(:endpoint_client) { instance_double(Google::Cloud::AIPlatform::V1::EndpointService::Client) }
  let(:prediction_client) { instance_double(Google::Cloud::AIPlatform::V1::PredictionService::Client) }
  let(:mock_response) do
    instance_double(
      "response",
      data: JSON.generate(
        {
          prediction: [
            {
              confidences: [0.95],
              display_names: ["Class A"],
              ids: ["12345"]
            }
          ]
        }
      )
    )
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(Google::Cloud::AIPlatform::V1::EndpointService::Client).to receive(:new).and_return(endpoint_client)
        allow(Google::Cloud::AIPlatform::V1::PredictionService::Client).to receive(:new).and_return(prediction_client)
        allow(endpoint_client).to receive(:get_endpoint).with(name: "projects/test-project-123/locations/us-central1/endpoints/test-endpoint-123").and_return(double("response", success?: true))

        message = client.check_connection(sync_config_json[:source][:connection_specification])
        result = message.connection_status
        expect(result).to be_a(Multiwoven::Integrations::Protocol::ConnectionStatus)
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(Google::Cloud::AIPlatform::V1::EndpointService::Client).to receive(:new).and_return(endpoint_client)
        allow(Google::Cloud::AIPlatform::V1::PredictionService::Client).to receive(:new).and_return(prediction_client)
        allow(endpoint_client).to receive(:get_endpoint).with(name: "projects/test-project-123/locations/us-central1/endpoints/test-endpoint-123").and_raise(StandardError.new("Connection failed"))

        message = client.check_connection(sync_config_json[:source][:connection_specification])
        result = message.connection_status
        expect(result).to be_a(Multiwoven::Integrations::Protocol::ConnectionStatus)
        expect(result.status).to eq("failed")
      end
    end
  end

  describe "#discover" do
    it "successfully returns the catalog message" do
      message = client.discover(nil)
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.request_rate_limit).to eql(600)
      expect(catalog.request_rate_limit_unit).to eql("minute")
      expect(catalog.request_rate_concurrency).to eql(10)
    end

    it "handles exceptions during discovery" do
      allow(client).to receive(:read_json).and_raise(StandardError.new("test error"))
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError),
        hash_including(context: "GOOGLE:VERTEX MODEL:DISCOVER:EXCEPTION", type: "error")
      )
      client.discover
    end
  end

  describe "#read" do
    context "when the read is successful" do
      it "successfully reads records" do
        allow(Google::Cloud::AIPlatform::V1::EndpointService::Client).to receive(:new).and_return(endpoint_client)
        allow(Google::Cloud::AIPlatform::V1::PredictionService::Client).to receive(:new).and_return(prediction_client)
        allow(client).to receive(:build_url).and_return("http://mock-url")
        expected_http_body = Google::Api::HttpBody.new(
          data: JSON.generate(
            {
              "instances" => {
                "content" => "Movie was good"
              }
            }
          )
        )
        allow(prediction_client).to receive(:raw_predict)
          .with(endpoint: "http://mock-url", http_body: expected_http_body)
          .and_return(mock_response)

        records = client.read(sync_config)
        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(records.first.record.data).to eq(
          {
            "prediction" => [{
              "confidences" => [0.95],
              "display_names" => ["Class A"],
              "ids" => ["12345"]
            }]
          }
        )
      end
    end

    context "when the read is failed" do
      it "handles exceptions during reading" do
        error_instance = StandardError.new("test error")
        allow(client).to receive(:run_model).and_raise(error_instance)
        expect(client).to receive(:handle_exception).with(
          error_instance,
          hash_including(context: "GOOGLE:VERTEX MODEL:READ:EXCEPTION", type: "error")
        )

        client.read(sync_config)
      end
    end
  end
end
