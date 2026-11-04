# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    RSpec.describe BaseConnector do
      describe "#connector_spec" do
        xit "raises an error for not being implemented" do
          connector = described_class.new
          expect { connector.connector_spec }.to raise_error("Not implemented")
        end
      end

      describe "#check_connection" do
        it "raises an error" do
          expect { described_class.new.check_connection({}) }.to raise_error("Not implemented")
        end
      end

      describe "#discover" do
        it "raises an error for not being implemented" do
          connector = described_class.new
          expect { connector.discover({}) }.to raise_error("Not implemented")
        end
      end

      describe "#http_error_message" do
        let(:connector) { SourceConnector.new }

        it "returns failed when the response is nil" do
          expect(connector.send(:http_error_message, nil)).to eq("failed")
        end

        it "extracts nested provider error messages" do
          response = instance_double(Net::HTTPResponse, body: { error: { message: "Invalid API key" } }.to_json)

          expect(connector.send(:http_error_message, response)).to eq("Invalid API key")
        end

        it "extracts the first message from an errors array" do
          response = instance_double(
            Net::HTTPResponse,
            body: { errors: [{ message: "Invalid authentication token" }] }.to_json
          )

          expect(connector.send(:http_error_message, response)).to eq("Invalid authentication token")
        end

        it "returns a scalar error value" do
          response = instance_double(Net::HTTPResponse, body: { error: "quota exceeded" }.to_json)

          expect(connector.send(:http_error_message, response)).to eq("quota exceeded")
        end

        it "falls back to the raw body for a JSON array" do
          response = instance_double(Net::HTTPResponse, body: [{ code: 500 }].to_json)

          expect(connector.send(:http_error_message, response)).to eq('[{"code":500}]')
        end

        it "falls back to the raw body for a JSON scalar" do
          response = instance_double(Net::HTTPResponse, body: '"service unavailable"')

          expect(connector.send(:http_error_message, response)).to eq('"service unavailable"')
        end

        it "falls back to the raw body when the response is not JSON" do
          response = instance_double(Net::HTTPResponse, body: "service unavailable")

          expect(connector.send(:http_error_message, response)).to eq("service unavailable")
        end

        it "extracts the first entry when error is an array of strings" do
          response = instance_double(Net::HTTPResponse, body: { error: ["bad key"] }.to_json)

          expect(connector.send(:http_error_message, response)).to eq("bad key")
        end

        it "prefers error_description over a bare OAuth error code" do
          response = instance_double(
            Net::HTTPResponse,
            body: { error: "invalid_client", error_description: "Client authentication failed" }.to_json
          )

          expect(connector.send(:http_error_message, response)).to eq("Client authentication failed")
        end

        it "reads error_description when no error key is present" do
          response = instance_double(Net::HTTPResponse, body: { error_description: "Token expired" }.to_json)

          expect(connector.send(:http_error_message, response)).to eq("Token expired")
        end

        it "reports the status code instead of dumping an HTML error page" do
          response = instance_double(
            Net::HTTPResponse,
            body: "<!DOCTYPE html><html><body>#{"Attention Required " * 500}</body></html>",
            code: "403"
          )

          expect(connector.send(:http_error_message, response)).to eq("HTTP 403")
        end

        it "caps an oversized plain-text body" do
          response = instance_double(Net::HTTPResponse, body: "z" * 2_000, code: "502")

          message = connector.send(:http_error_message, response)

          expect(message.length).to eq(500)
          expect(message).to end_with("...")
        end

        it "reports the status code when the body is blank" do
          response = instance_double(Net::HTTPResponse, body: "", code: "504")

          expect(connector.send(:http_error_message, response)).to eq("HTTP 504")
        end

        it "survives a body with invalid UTF-8 bytes" do
          response = instance_double(Net::HTTPResponse, body: "bad \xC3 byte".dup.force_encoding("UTF-8"), code: "500")

          expect { connector.send(:http_error_message, response) }.not_to raise_error
        end

        it "does not leak a Ruby error when reading the body raises" do
          response = instance_double(Net::HTTPResponse, code: "500")
          allow(response).to receive(:body).and_raise(IOError, "connection reset")

          expect(connector.send(:http_error_message, response)).to eq("HTTP 500")
        end
      end

      describe "#failure_status_from_response" do
        let(:connector) { SourceConnector.new }

        it "returns a failed connection status with the parsed provider message" do
          response = instance_double(
            Net::HTTPResponse,
            body: { error: { message: "Your credit balance is too low" } }.to_json
          )

          message = connector.send(:failure_status_from_response, response)

          expect(message.connection_status.status).to eq("failed")
          expect(message.connection_status.message).to include("credit balance is too low")
        end
      end
    end
  end
end
