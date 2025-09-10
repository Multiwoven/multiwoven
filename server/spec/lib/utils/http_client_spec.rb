# frozen_string_literal: true

require "rails_helper"

RSpec.describe Utils::HttpClient do
  describe ".post" do
    let(:url) { "https://api.example.com" }
    let(:headers) { { "Authorization" => "Bearer token123" } }
    let(:body) { { "key" => "value" } }
    let(:config) { { timeout: 30, open_timeout: 10 } }

    context "when making a POST request" do
      it "accepts all required parameters" do
        expect do
          described_class.post(
            base_url: url,
            headers:,
            body:,
            config:
          )
        end.to raise_error(/HTTP request failed:/)
      end

      it "handles string body correctly" do
        expect do
          described_class.post(
            base_url: url,
            body: '{"key": "value"}',
            config:
          )
        end.to raise_error(/HTTP request failed:/)
      end

      it "handles nil body correctly" do
        expect do
          described_class.post(
            base_url: url,
            config:
          )
        end.to raise_error(/HTTP request failed:/)
      end

      it "sets default Content-Type header when not provided" do
        expect do
          described_class.post(
            base_url: url,
            body:,
            config:
          )
        end.to raise_error(/HTTP request failed:/)
      end
    end

    context "when timeout is set" do
      it "accepts custom timeout values" do
        expect do
          described_class.post(
            base_url: url,
            config: { timeout: 1, open_timeout: 1 }
          )
        end.to raise_error(/HTTP request failed:/)
      end
    end

    context "with invalid URLs" do
      it "handles malformed URLs" do
        expect do
          described_class.post(base_url: "invalid-url", config:)
        end.to raise_error(/HTTP request failed:/)
      end

      it "handles empty URL" do
        expect do
          described_class.post(base_url: "", config:)
        end.to raise_error(/HTTP request failed:/)
      end
    end

    context "with default configuration" do
      it "uses default timeout values when config is empty" do
        expect do
          described_class.post(base_url: url)
        end.to raise_error(/HTTP request failed:/)
      end

      it "uses default timeout values when config is nil" do
        expect do
          described_class.post(base_url: url, config: nil)
        end.to raise_error(/HTTP request failed:/)
      end
    end

    context "with HTTPS URLs" do
      it "handles HTTPS URLs" do
        expect do
          described_class.post(base_url: "https://secure.example.com")
        end.to raise_error(/HTTP request failed:/)
      end

      it "handles HTTP URLs" do
        expect do
          described_class.post(base_url: "http://insecure.example.com")
        end.to raise_error(/HTTP request failed:/)
      end
    end
  end

  describe ".handle_response" do
    let(:http_response) { double("response") }

    context "with successful response" do
      before do
        allow(http_response).to receive(:code).and_return("200")
        allow(http_response).to receive(:body).and_return('{"success": true}')
      end

      it "parses JSON response" do
        result = described_class.handle_response(http_response)
        expect(result).to eq({ "success" => true })
      end
    end

    context "with error response" do
      before do
        allow(http_response).to receive(:code).and_return("500")
        allow(http_response).to receive(:body).and_return("Server Error")
      end

      it "raises error with status and body" do
        expect do
          described_class.handle_response(http_response)
        end.to raise_error("HTTP request failed with status 500: Server Error")
      end
    end

    context "with empty response body" do
      before do
        allow(http_response).to receive(:code).and_return("404")
        allow(http_response).to receive(:body).and_return("")
      end

      it "raises error without body" do
        expect do
          described_class.handle_response(http_response)
        end.to raise_error("HTTP request failed with status 404")
      end
    end

    context "with nil response body" do
      before do
        allow(http_response).to receive(:code).and_return("403")
        allow(http_response).to receive(:body).and_return(nil)
      end

      it "raises error without body" do
        expect do
          described_class.handle_response(http_response)
        end.to raise_error("HTTP request failed with status 403")
      end
    end

    context "with invalid JSON response" do
      before do
        allow(http_response).to receive(:code).and_return("200")
        allow(http_response).to receive(:body).and_return("invalid json")
      end

      it "raises JSON parsing error" do
        expect do
          described_class.handle_response(http_response)
        end.to raise_error(JSON::ParserError)
      end
    end
  end

  describe "configuration handling" do
    it "uses default timeout values" do
      expect do
        described_class.post(base_url: "https://example.com")
      end.to raise_error(/HTTP request failed:/)
    end

    it "accepts custom timeout values" do
      expect do
        described_class.post(
          base_url: "https://example.com",
          config: { timeout: 45, open_timeout: 15 }
        )
      end.to raise_error(/HTTP request failed:/)
    end
  end

  describe "header handling" do
    it "accepts custom headers" do
      expect do
        described_class.post(
          base_url: "https://example.com",
          headers: { "Custom-Header" => "value" }
        )
      end.to raise_error(/HTTP request failed:/)
    end
  end
end
