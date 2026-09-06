# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConnectorDefinitions::FilterConnectorDefinitions, type: :interactor do
  let(:workspace) { create(:workspace) }
  let(:connectors) do
    {
      source: [
        { name: "Postgresql", category: "Database", connector_type: "source" },
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
  let(:source_connector) { create(:connector, workspace:, connector_type: "source", connector_name: "Postgresql") }
  let(:destination_connector) do
    create(:connector, workspace:, connector_type: "destination", connector_name: "Klaviyo")
  end
  let(:hosted_data_store) { create(:hosted_data_store, workspace:, source_connector:, destination_connector:) }
  let(:template_data) do
    [
      {
        id: 1,
        template_id: "vector_store_hosted_connector",
        name: "AI Squared Vector Store",
        store_enabled: true,
        linked: true,
        linked_data_store_id: hosted_data_store.id
      }.with_indifferent_access
    ]
  end

  before do
    allow(Multiwoven::Integrations::Service).to receive(:connectors).and_return(connectors)
    # Default mock returns empty data for tests that don't need hosted data stores
    allow(HostedDataStores::HostedDataStoreTemplateList)
      .to receive(:call)
      .and_return(double(data: []))
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

        expect(result.connectors).to match_array([connectors[:source][3]])
      end

      it "returns only the Data Warehouse connectors for source type" do
        result = described_class.call(type: "source", category: "data")

        expect(result.connectors).to match_array(
          [connectors[:source][0], connectors[:source][1], connectors[:source][2]]
        )
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

    context "when filtering by hosted data stores" do
      before do
        # Override the default mock to return template data for this context
        allow(HostedDataStores::HostedDataStoreTemplateList)
          .to receive(:call)
          .with(workspace:)
          .and_return(double(data: template_data))
      end

      it "returns the hosted data stores" do
        result = described_class.call(type: "source", category: "data", workspace:)

        hosted_data_store_connector = result.connectors.find { |c| c[:title] == "AI Squared Vector Store" }
        expect(hosted_data_store_connector).to be_present
        expect(hosted_data_store_connector[:name]).to eq("AISquaredVectorStore")
        expect(hosted_data_store_connector[:in_host]).to be true
        expect(hosted_data_store_connector[:store_enabled]).to be true
        expect(hosted_data_store_connector[:in_host_store_id]).to eq(hosted_data_store.id)
        expect(hosted_data_store_connector[:icon]).to eq(Utils::Constants::HOSTED_DATA_STORE_ICON)
        # Should have 3 regular connectors (Postgresql, Snowflake, Redshift) + 1 hosted data store = 4
        expect(result.connectors.size).to eq(4)
      end
    end
  end
end
