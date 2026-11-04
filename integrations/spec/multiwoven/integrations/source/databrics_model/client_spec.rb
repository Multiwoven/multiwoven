# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::DatabricksModel::Client do
  let(:client) { described_class.new }
  let(:connection_config) do
    {
      databricks_host: "example.cloud.databricks.com",
      endpoint: "my-endpoint",
      token: "test-token"
    }
  end
  let(:health_endpoint) { "https://example.cloud.databricks.com/api/2.0/serving-endpoints/my-endpoint" }
  let(:headers) do
    {
      "Accept" => "application/json",
      "Authorization" => "Bearer test-token",
      "Content-Type" => "application/json"
    }
  end

  before do
    allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      before do
        response = Net::HTTPSuccess.new("1.1", "200", "OK")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return({ state: "READY" }.to_json)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(health_endpoint, "GET", headers: headers)
          .and_return(response)
      end

      it "returns a succeeded connection status" do
        message = client.check_connection(connection_config)
        result = message.connection_status

        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      let(:response_body) do
        {
          error_code: "INVALID_PARAMETER_VALUE",
          message: "Endpoint my-endpoint does not exist"
        }.to_json
      end

      before do
        response = Net::HTTPSuccess.new("1.1", "404", "Not Found")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(health_endpoint, "GET", headers: headers)
          .and_return(response)
      end

      it "returns a failed connection status with the provider error message" do
        message = client.check_connection(connection_config)
        result = message.connection_status

        expect(result.status).to eq("failed")
        expect(result.message).to include("Endpoint my-endpoint does not exist")
      end
    end
  end
end
