# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connectors::QuerySource, type: :interactor do
  describe ".call" do
    let(:connector) { instance_double("Connector") }
    let(:query) { "SELECT * FROM table_name" }
    let(:limit) { 50 }
    let(:mock_result) { [{ "column1" => "value1" }, { "column2" => "value2" }] } # Adjust as needed

    context "when the query executes successfully" do
      before do
        allow(connector).to receive(:execute_query).with(query, limit:).and_return(mock_result)
      end

      it "executes the query and returns records" do
        result = described_class.call(connector:, query:, limit:)
        expect(result).to be_a_success
        expect(result.records).to eq(mock_result)
      end
    end

    context "when the query returns no rows" do
      before do
        allow(connector).to receive(:execute_query).with(query, limit:).and_return([])
      end

      it "succeeds with empty records" do
        result = described_class.call(connector:, query:, limit:)
        expect(result).to be_a_success
        expect(result.records).to eq([])
      end
    end

    context "when the connector does not implement query" do
      before do
        allow(connector).to receive(:execute_query).with(query, limit:).and_return(nil)
      end

      it "fails with an unsupported query error without reporting an exception" do
        expect(Utils::ExceptionReporter).not_to receive(:report)
        result = described_class.call(connector:, query:, limit:)
        expect(result).to be_a_failure
        expect(result.error).to eq("This connector does not support querying")
      end
    end

    context "when the connector returns a log message instead of records" do
      let(:log_message) do
        Multiwoven::Integrations::Protocol::LogMessage.new(
          name: "OpenAI", level: "error", message: "request failed"
        ).to_multiwoven_message
      end

      before do
        allow(connector).to receive(:execute_query).with(query, limit:).and_return(log_message)
      end

      it "fails with the log message without reporting an exception" do
        expect(Utils::ExceptionReporter).not_to receive(:report)
        result = described_class.call(connector:, query:, limit:)
        expect(result).to be_a_failure
        expect(result.error).to eq("request failed")
      end
    end

    context "when the connector raises NotImplementedError" do
      before do
        allow(connector).to receive(:execute_query)
          .with(query, limit:).and_raise(NotImplementedError, "Structured data is not supported yet")
      end

      it "fails with an unsupported query error without reporting an exception" do
        expect(Utils::ExceptionReporter).not_to receive(:report)
        result = described_class.call(connector:, query:, limit:)
        expect(result).to be_a_failure
        expect(result.error).to eq("This connector does not support querying")
      end
    end

    context "when an error occurs during query execution" do
      before do
        allow(connector).to receive(:execute_query).with(query, limit:).and_raise(StandardError, "query failed")
      end

      it "fails and sets the error message" do
        result = described_class.call(connector:, query:, limit:)
        expect(result).to be_a_failure
      end
    end
  end
end
