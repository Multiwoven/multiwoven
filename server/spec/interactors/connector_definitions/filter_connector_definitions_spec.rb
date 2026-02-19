# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConnectorDefinitions::FilterConnectorDefinitions, type: :interactor do
  let(:connectors) do
    {
      source: [
<<<<<<< HEAD
        { name: "Snowflake", category: "Data Warehouse", connector_type: "source" },
        { name: "Redshift", category: "Data Warehouse", connector_type: "source" },
        { name: "DatabricksModel", category: "AI Model", connector_type: "source" }
=======
        { name: "Postgresql", category: "Database", sub_category: "Relational Database", connector_type: "source" },
        { name: "Snowflake", category: "Data Warehouse", sub_category: "Relational Database",
          connector_type: "source" },
        { name: "Redshift", category: "Data Warehouse", sub_category: "Relational Database", connector_type: "source" },
        { name: "DatabricksModel", category: "AI Model", sub_category: "AI_ML Service", connector_type: "source" },
        { name: "OpenAI", category: "AI Model", sub_category: "LLM", connector_type: "source" },
        { name: "Anthropic", category: "AI Model", sub_category: "LLM", connector_type: "source" },
        { name: "PineconeDB", category: "Database", sub_category: "Vector Database", connector_type: "source" },
        { name: "Firecrawl", category: "Data Warehouse", sub_category: "Web Scraper", connector_type: "source" }
>>>>>>> a81cf23d0 (chore(CE): connector model extraction api changes (#1609))
      ],
      destination: [
        { name: "Klaviyo", category: "Marketing Automation", sub_category: "Relational Database",
          connector_type: "destination" },
        { name: "SalesforceCrm", category: "CRM", sub_category: "Relational Database", connector_type: "destination" },
        { name: "FacebookCustomAudience", category: "Ad-Tech", sub_category: "Relational Database",
          connector_type: "destination" },
        { name: "Qdrant", category: "Database", sub_category: "Vector Database", connector_type: "destination" }
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

<<<<<<< HEAD
        expect(result.connectors).to match_array([connectors[:source][2]])
=======
        expect(result.connectors).to match_array([connectors[:source][3], connectors[:source][4],
                                                  connectors[:source][5]])
        expect(result.connectors.map { |c| c[:name] }).to match_array(%w[DatabricksModel OpenAI Anthropic])
>>>>>>> a81cf23d0 (chore(CE): connector model extraction api changes (#1609))
      end

      it "returns only the Data Warehouse connectors for source type" do
        result = described_class.call(type: "source", category: "data")

<<<<<<< HEAD
        expect(result.connectors).to match_array([connectors[:source][0], connectors[:source][1]])
=======
        # Should include Database (Postgresql, PineconeDB), Data Warehouse (Snowflake, Redshift, Firecrawl)
        expect(result.connectors).to match_array(
          [connectors[:source][0], connectors[:source][1], connectors[:source][2], connectors[:source][6],
           connectors[:source][7]]
        )
        expect(result.connectors.map do |c|
                 c[:name]
               end).to match_array(%w[Postgresql Snowflake Redshift PineconeDB Firecrawl])
>>>>>>> a81cf23d0 (chore(CE): connector model extraction api changes (#1609))
      end

      it "returns only the data category connectors for destination type" do
        result = described_class.call(type: "destination", category: "data")

        # Should include Marketing Automation (Klaviyo), CRM (SalesforceCrm),
        # Ad-Tech (FacebookCustomAudience), Database (Qdrant)
        expect(result.connectors).to match_array([connectors[:destination][0], connectors[:destination][1],
                                                  connectors[:destination][2], connectors[:destination][3]])
      end
    end

    context "when no category is specified" do
      it "returns all connectors of the specified type" do
        result = described_class.call(type: "destination")

        expect(result.connectors).to match_array(connectors[:destination])
      end
    end
<<<<<<< HEAD
=======

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
        # Should have 5 regular connectors (Postgresql, Snowflake, Redshift, PineconeDB, Firecrawl)
        # + 1 hosted data store = 6
        expect(result.connectors.size).to eq(6)
      end
    end

    context "when filtering by sub_category" do
      it "returns only LLM connectors for source type" do
        result = described_class.call(type: "source", sub_category: "llm")

        expect(result.connectors).to match_array([connectors[:source][4], connectors[:source][5]])
        expect(result.connectors.map { |c| c[:name] }).to match_array(%w[OpenAI Anthropic])
      end

      it "returns only database connectors for source type" do
        result = described_class.call(type: "source", sub_category: "database")

        expect(result.connectors).to match_array([connectors[:source][0], connectors[:source][1],
                                                  connectors[:source][2]])
        expect(result.connectors.map { |c| c[:name] }).to match_array(%w[Postgresql Snowflake Redshift])
      end

      it "returns only vector database connectors for source type" do
        result = described_class.call(type: "source", sub_category: "vector")

        expect(result.connectors).to match_array([connectors[:source][6]])
        expect(result.connectors.first[:name]).to eq("PineconeDB")
      end

      it "returns only web scraper connectors for source type" do
        result = described_class.call(type: "source", sub_category: "web")

        expect(result.connectors).to match_array([connectors[:source][7]])
        expect(result.connectors.first[:name]).to eq("Firecrawl")
      end

      it "returns only AI/ML service connectors for source type" do
        result = described_class.call(type: "source", sub_category: "ai_ml_service")

        expect(result.connectors).to match_array([connectors[:source][3]])
        expect(result.connectors.first[:name]).to eq("DatabricksModel")
      end

      it "returns only vector database connectors for destination type" do
        result = described_class.call(type: "destination", sub_category: "vector")

        expect(result.connectors).to match_array([connectors[:destination][3]])
        expect(result.connectors.first[:name]).to eq("Qdrant")
      end
    end

    context "when filtering by both category and sub_category" do
      it "returns only AI Model connectors with LLM sub_category" do
        result = described_class.call(type: "source", category: "ai_ml", sub_category: "llm")

        expect(result.connectors).to match_array([connectors[:source][4], connectors[:source][5]])
        expect(result.connectors.map { |c| c[:name] }).to match_array(%w[OpenAI Anthropic])
      end

      it "returns only Database connectors with Vector Database sub_category" do
        result = described_class.call(type: "source", category: "Database", sub_category: "vector")

        expect(result.connectors).to match_array([connectors[:source][6]])
        expect(result.connectors.first[:name]).to eq("PineconeDB")
      end

      it "returns only Data Warehouse connectors with Relational Database sub_category" do
        result = described_class.call(type: "source", category: "data", sub_category: "database")

        expect(result.connectors).to match_array([connectors[:source][0], connectors[:source][1],
                                                  connectors[:source][2]])
        expect(result.connectors.map { |c| c[:name] }).to match_array(%w[Postgresql Snowflake Redshift])
      end
    end

    context "when filtering by sub_category with both source and destination" do
      it "returns connectors from both types when no type is specified" do
        result = described_class.call(sub_category: "vector")

        expect(result.connectors[:source]).to match_array([connectors[:source][6]])
        expect(result.connectors[:destination]).to match_array([connectors[:destination][3]])
      end
    end

    context "when filtering by custom sub_category" do
      it "returns connectors matching the exact sub_category string" do
        result = described_class.call(type: "source", sub_category: "Relational Database")

        expect(result.connectors).to match_array([connectors[:source][0], connectors[:source][1],
                                                  connectors[:source][2]])
      end
    end
>>>>>>> a81cf23d0 (chore(CE): connector model extraction api changes (#1609))
  end
end
