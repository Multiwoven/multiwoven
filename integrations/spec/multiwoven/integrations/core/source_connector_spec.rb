# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    RSpec.describe SourceConnector do
      let(:connector) { described_class.new }

      describe "#read" do
        it "raises an error for not being implemented" do
          expect { connector.read({}) }.to raise_error("Not implemented")
        end
      end

      describe "#batched_query" do
        it "adds LIMIT and OFFSET to a query" do
          sql_query = String.new("SELECT * FROM table")
          limit = 10
          offset = 20

          result = connector.send(:batched_query, sql_query, limit, offset)
          expect(result).to eq("SELECT * FROM table LIMIT 10 OFFSET 20")
        end

        it "raises an error if offset is negative" do
          sql_query = "SELECT * FROM table"
          limit = 10
          offset = -1

          expect { connector.send(:batched_query, sql_query, limit, offset) }.to raise_error(ArgumentError, "Offset and limit must be non-negative")
        end

        it "raises an error if limit is negative" do
          sql_query = "SELECT * FROM table"
          limit = -1
          offset = 20

          expect { connector.send(:batched_query, sql_query, limit, offset) }.to raise_error(ArgumentError, "Offset and limit must be non-negative")
        end

        it "raises an error if query already has a LIMIT clause" do
          sql_query = String.new("SELECT * FROM table LIMIT 5")
          limit = 10
          offset = 20

          expect { connector.send(:batched_query, sql_query, limit, offset) }.to raise_error(ArgumentError, "Query already contains a LIMIT clause")
        end

        it "removes trailing semicolons" do
          sql_query = String.new("SELECT * FROM table;")
          limit = 10
          offset = 20

          result = connector.send(:batched_query, sql_query, limit, offset)
          expect(result).to eq("SELECT * FROM table LIMIT 10 OFFSET 20")
        end
      end

      describe "#send_request" do
        it "delegates to HttpClient.request" do
          options = {
            url: "https://example.com",
            http_method: "GET",
            payload: { key: "value" },
            headers: { "Content-Type" => "application/json" },
            config: { timeout: 30 }
          }

          expect(HttpClient).to receive(:request).with(
            options[:url],
            options[:http_method],
            payload: options[:payload],
            headers: options[:headers],
            config: options[:config]
          )

          connector.send(:send_request, options)
        end
      end

      describe "#send_streaming_request" do
        it "delegates to StreamingHttpClient.request" do
          options = {
            url: "https://example.com",
            http_method: "GET",
            payload: { key: "value" },
            headers: { "Content-Type" => "application/json" },
            config: { timeout: 30 }
          }

          expect(StreamingHttpClient).to receive(:request).with(
            options[:url],
            options[:http_method],
            payload: options[:payload],
            headers: options[:headers],
            config: options[:config]
          ).and_yield("chunk1").and_yield("chunk2")

          chunks = []
          connector.send(:send_streaming_request, options) do |chunk|
            chunks << chunk
          end

          expect(chunks).to eq(%w[chunk1 chunk2])
        end
      end
    end
  end
end
