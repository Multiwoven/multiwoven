# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    RSpec.describe StreamingHttpClient do
      describe ".request" do
        let(:url) { "https://example.com/api/stream" }
        let(:method) { "GET" }
        let(:headers) { { "Authorization" => "Bearer token" } }
        let(:config) { { timeout: 5 } }
        let(:mock_response) { double("Net::HTTPResponse", code: "200") }

        it "makes a streaming HTTP request" do
          http = double("Net::HTTP")
          allow(Net::HTTP).to receive(:new).and_return(http)
          allow(http).to receive(:use_ssl=)
          allow(http).to receive(:open_timeout=)
          allow(http).to receive(:read_timeout=)
          allow(http).to receive(:request) do |&block|
            block.call(mock_response)
          end

          allow(mock_response).to receive(:read_body) do |&block|
            block.call("chunk1")
            block.call("chunk2")
            block.call("chunk3")
          end
          chunks = []
          described_class.request(url, method, headers: headers, config: config) do |chunk|
            chunks << chunk
          end
          expect(chunks).to eq(%w[chunk1 chunk2 chunk3])
        end

        it "handles errors gracefully" do
          http = double("Net::HTTP")
          allow(Net::HTTP).to receive(:new).and_return(http)
          allow(http).to receive(:use_ssl=)
          allow(http).to receive(:open_timeout=)
          allow(http).to receive(:read_timeout=)
          allow(http).to receive(:request) do |&block|
            block.call(mock_response)
          end

          allow(mock_response).to receive(:read_body).and_raise(StandardError, "Network error")

          expect do
            described_class.request(url, method, headers: headers, config: config) { |_| }
          end.to raise_error(StandardError, "Network error")
        end
      end
    end
  end
end
