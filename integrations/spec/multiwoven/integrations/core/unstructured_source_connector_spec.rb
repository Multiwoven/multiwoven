# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    RSpec.describe UnstructuredSourceConnector do
      let(:connector) { described_class.new }

      describe "#unstructured_data?" do
        it "returns true when data_type is unstructured" do
          connection_config = { "data_type" => "unstructured" }
          expect(connector.unstructured_data?(connection_config)).to be true
        end

        it "returns false when data_type is not unstructured" do
          connection_config = { "data_type" => "structured" }
          expect(connector.unstructured_data?(connection_config)).to be false
        end

        it "returns false when data_type is not specified" do
          connection_config = {}
          expect(connector.unstructured_data?(connection_config)).to be false
        end
      end

      describe "#create_unstructured_stream" do
        it "creates a stream with the correct configuration" do
          stream = connector.create_unstructured_stream

          expect(stream.name).to eq("unstructured")
          expect(stream.action.to_s).to eq("fetch")
          expect(stream.json_schema).to eq(UnstructuredSourceConnector::UNSTRUCTURED_SCHEMA)
          expect(stream.supported_sync_modes).to eq(["incremental"])
          expect(stream.source_defined_cursor).to be true
          expect(stream.default_cursor_field).to eq(["modified_date"])
          expect(stream.source_defined_primary_key).to eq([["element_id"]])
        end
      end
    end
  end
end
