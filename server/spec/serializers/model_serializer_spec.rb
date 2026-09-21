# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModelSerializer, type: :serializer do
  let(:workspace) { create(:workspace) }
  let(:source) { create(:connector, connector_type: "source", connector_name: "Snowflake", workspace:) }

  describe "#configuration" do
    context "when model is not ai_ml" do
      let(:model) do
        create(:model,
               connector: source,
               workspace:,
               query_type: :raw_sql,
               query: "SELECT 1",
               configuration: nil)
      end

      it "returns masked_configuration" do
        model.configuration = { "host" => "localhost" }
        allow(model).to receive(:masked_configuration).and_return({ "host" => "localhost" })
        serializer = described_class.new(model)
        expect(serializer.attributes[:configuration]).to eq({ "host" => "localhost" })
      end
    end

    context "when model is ai_ml" do
      let(:ai_ml_connector) do
        create(:connector, connector_type: "source", connector_name: "OpenAI", workspace:)
      end
      let(:json_schema) { { "type" => "object", "properties" => { "prompt" => { "type" => "string" } } } }
      let(:model) do
        Model.new(
          connector: ai_ml_connector,
          workspace:,
          query_type: :ai_ml,
          name: "test ai model",
          configuration: { "harvesters" => [] }
        )
      end
      let(:mock_catalog) { instance_double(Catalog) }

      before do
        allow(ai_ml_connector).to receive(:catalog).and_return(mock_catalog)
        allow(mock_catalog).to receive(:json_schema).and_return(json_schema)
        allow(model).to receive(:masked_configuration).and_return({ "harvesters" => [] })
      end

      it "merges json_schema into masked_configuration" do
        serializer = described_class.new(model)
        result = serializer.attributes[:configuration]
        expect(result["harvesters"]).to eq([])
        expect(result[:json_schema]).to eq(json_schema)
      end
    end
  end
end
