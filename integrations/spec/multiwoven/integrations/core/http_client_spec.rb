# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    RSpec.describe HttpClient do
      describe ".request" do
        let(:url) { "http://example.com" }
        let(:headers) { { "Content-Type" => "application/json" } }
        let(:payload) { { data: "test" } }
        before do
          stub_request(:any, url)
        end

        context "when making a GET request" do
          it "creates a GET request" do
            described_class.request(url, "GET", headers: headers)
            expect(a_request(:get, url).with(headers: headers)).to have_been_made.once
          end
        end

        context "when making a POST request" do
          it "creates a POST request with the correct body and headers" do
            described_class.request(url, "POST", payload: payload, headers: headers)
            expect(a_request(:post, url).with(body: payload.to_json, headers: headers)).to have_been_made.once
          end
        end

        context "when making a PUT request" do
          it "creates a PUT request with the correct body and headers" do
            described_class.request(url, "PUT", payload: payload, headers: headers)
            expect(a_request(:put, url).with(body: payload.to_json, headers: headers)).to have_been_made.once
          end
        end

        context "when making a DELETE request" do
          it "creates a DELETE request" do
            described_class.request(url, "DELETE", headers: headers)
            expect(a_request(:delete, url).with(headers: headers)).to have_been_made.once
          end
        end

        context "with an unsupported HTTP method" do
          it "raises an ArgumentError" do
            expect { described_class.request(url, "INVALID", headers: headers) }.to raise_error(ArgumentError)
          end
        end
      end
    end
  end
end
