# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConnectorDefinitions::FilterConnectors, type: :interactor do
  let(:connectors) do
    {
      source: [
        { name: "Snowflake", category: "Data Warehouse", connector_type: "source" },
        { name: "Redshift", category: "Data Warehouse", connector_type: "source" },
        { name: "DatabricksModel", category: "AI Model", connector_type: "source" }
      ],
      destination: [
        { name: "Klaviyo", category: "Marketing Automation", connector_type: "destination" },
        { name: "SalesforceCrm", category: "CRM", connector_type: "destination" },
        { name: "FacebookCustomAudience", category: "Ad-Tech", connector_type: "destination" }
      ]
    }.with_indifferent_access
  end

  before do
    allow(Multiwoven::Integrations::Service).to receive(:connectors).and_return(connectors)
  end

  describe "#call" do
    context "when filtering by type only" do
      it "returns only the destination connectors when type is destination" do
        result = described_class.call(type: "destination")

        expect(result.connectors).to match_array(connectors[:destination])
      end

      it "returns only the source connectors when type is source" do
        result = described_class.call(type: "source")

        expect(result.connectors).to match_array(connectors[:source])
      end
    end

    context "when filtering by category and type" do
      it "returns only the AI Model connectors for source type" do
        result = described_class.call(type: "source", category: "ai_ml")

        expect(result.connectors).to match_array([connectors[:source][2]])
      end

      it "returns only the Data Warehouse connectors for source type" do
        result = described_class.call(type: "source", category: "data")

        expect(result.connectors).to match_array([connectors[:source][0], connectors[:source][1]])
      end

      it "returns only the Marketing Automation connectors for destination type" do
        result = described_class.call(type: "destination", category: "data")

        expect(result.connectors).to match_array([connectors[:destination][0], connectors[:destination][1],
                                                  connectors[:destination][2]])
      end
    end

    context "when no category is specified" do
      it "returns all connectors of the specified type" do
        result = described_class.call(type: "destination")

        expect(result.connectors).to match_array(connectors[:destination])
      end
    end
  end
end
