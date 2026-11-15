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

    context "when an error occurs during query execution" do
      before do
        allow(connector).to receive(:execute_query).with(query, limit:).and_raise(StandardError, "query failed")
      end

      it "fails, sets the error message and reports the exception" do
        expect(Utils::ExceptionReporter).to receive(:report).with(an_instance_of(StandardError))
        result = described_class.call(connector:, query:, limit:)
        expect(result).to be_a_failure
        expect(result.error).to eq("query failed")
      end
    end

    [
      PG::UndefinedColumn, PG::UndefinedTable, PG::UndefinedFunction, PG::InvalidTextRepresentation
    ].each do |error_class|
      context "when the query raises #{error_class}" do
        let(:message) { "ERROR:  #{error_class.name} raised by the source" }

        before do
          allow(connector).to receive(:execute_query).with(query, limit:).and_raise(error_class.new(message))
        end

        it "fails with the database message without reporting an exception" do
          expect(Utils::ExceptionReporter).not_to receive(:report)
          result = described_class.call(connector:, query:, limit:)
          expect(result).to be_a_failure
          expect(result.error).to include(message)
        end

        it "logs the error class at info level without the database message" do
          allow(Rails.logger).to receive(:info)
          described_class.call(connector:, query:, limit:)
          expect(Rails.logger).to have_received(:info)
            .with("Connectors::QuerySource query rejected by source: #{error_class}")
        end
      end
    end

    [PG::ConnectionBad, PG::UnableToSend, PG::SyntaxError, PG::InsufficientPrivilege].each do |error_class|
      context "when the query raises #{error_class}" do
        let(:error) { error_class.new("#{error_class.name} raised by the source") }

        before do
          allow(connector).to receive(:execute_query).with(query, limit:).and_raise(error)
        end

        it "fails with the database message and reports the exception" do
          expect(Utils::ExceptionReporter).to receive(:report).with(error)
          result = described_class.call(connector:, query:, limit:)
          expect(result).to be_a_failure
          expect(result.error).to eq(error.message)
        end
      end
    end
  end
end
