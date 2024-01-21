# frozen_string_literal: true

require "rails_helper"

RSpec.describe Models::ExecuteQuery, type: :interactor do
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

      it "fails and sets the error message" do
        result = described_class.call(connector:, query:, limit:)
        expect(result).to be_a_failure
        expect(result.errors).to eq("query failed")
      end
    end
  end
end
