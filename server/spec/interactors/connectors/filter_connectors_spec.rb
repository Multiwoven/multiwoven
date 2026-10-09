# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connectors::FilterConnectors do
  let(:workspace) { create(:workspace) }

  let!(:source_connector) do
    create(:connector, workspace:, connector_type: "source", connector_name: "Snowflake")
  end

  let!(:destination_connector) do
    create(:connector, workspace:, connector_type: "destination", connector_name: "Klaviyo")
  end

  describe "#call" do
    context "without any filters" do
      it "returns all connectors for the workspace" do
        result = described_class.call(workspace:)

        expect(result.success?).to be true
        expect(result.connectors).to include(source_connector, destination_connector)
      end
    end

    context "with type filter" do
      it "returns only source connectors when type is source" do
        result = described_class.call(workspace:, type: "source")

        expect(result.success?).to be true
        expect(result.connectors).to include(source_connector)
        expect(result.connectors).not_to include(destination_connector)
      end

      it "returns only destination connectors when type is destination" do
        result = described_class.call(workspace:, type: "destination")

        expect(result.success?).to be true
        expect(result.connectors).to include(destination_connector)
        expect(result.connectors).not_to include(source_connector)
      end

      it "handles uppercase type filter" do
        result = described_class.call(workspace:, type: "SOURCE")

        expect(result.success?).to be true
        expect(result.connectors).to include(source_connector)
        expect(result.connectors).not_to include(destination_connector)
      end
    end

    context "with category filter" do
      let!(:ai_ml_connector) do
        create(:connector, workspace:, connector_type: "source",
                           connector_name: "OpenAI", connector_category: "AI Model")
      end

      let!(:data_connector) do
        create(:connector, workspace:, connector_type: "source",
                           connector_name: "Postgres", connector_category: "Database")
      end

      it "returns only ai_ml connectors when category is ai_ml" do
        result = described_class.call(workspace:, category: "ai_ml")

        expect(result.success?).to be true
        expect(result.connectors).to include(ai_ml_connector)
        expect(result.connectors).not_to include(data_connector)
      end

      it "returns only data connectors when category is data" do
        result = described_class.call(workspace:, category: "data")

        expect(result.success?).to be true
        expect(result.connectors).to include(data_connector)
        expect(result.connectors).not_to include(ai_ml_connector)
      end
    end

    context "with sub_category filter" do
      let!(:llm_connector) do
        create(:connector, workspace:, connector_type: "source",
                           connector_name: "OpenAI", connector_sub_category: "LLM")
      end

      let!(:database_connector) do
        create(:connector, workspace:, connector_type: "source",
                           connector_name: "Postgres", connector_sub_category: "Relational Database")
      end

      it "returns only llm connectors when sub_category is llm" do
        result = described_class.call(workspace:, sub_category: "llm")

        expect(result.success?).to be true
        expect(result.connectors).to include(llm_connector)
      end

      it "returns only database connectors when sub_category is database" do
        result = described_class.call(workspace:, sub_category: "database")

        expect(result.success?).to be true
        expect(result.connectors).to include(database_connector)
      end
    end

    context "with provider filter" do
      it "returns connectors matching the provider name" do
        result = described_class.call(workspace:, provider: "Snowflake")

        expect(result.success?).to be true
        expect(result.connectors).to include(source_connector)
        expect(result.connectors).not_to include(destination_connector)
      end

      it "returns empty when provider does not match any connector" do
        result = described_class.call(workspace:, provider: "NonExistent")

        expect(result.success?).to be true
        expect(result.connectors).to be_empty
      end
    end

    context "with multiple filters" do
      let!(:another_source_connector) do
        create(:connector, workspace:, connector_type: "source", connector_name: "Postgres")
      end

      it "applies all filters together" do
        result = described_class.call(workspace:, type: "source", provider: "Snowflake")

        expect(result.success?).to be true
        expect(result.connectors).to include(source_connector)
        expect(result.connectors).not_to include(destination_connector)
        expect(result.connectors).not_to include(another_source_connector)
      end
    end

    context "with pagination" do
      it "paginates results with specified page and per_page" do
        result = described_class.call(workspace:, page: 1, per_page: 1)

        expect(result.success?).to be true
        expect(result.connectors.size).to eq(1)
      end

      it "returns second page of results" do
        result = described_class.call(workspace:, page: 2, per_page: 1)

        expect(result.success?).to be true
        expect(result.connectors.size).to eq(1)
      end

      it "defaults to page 1 when page is not provided" do
        result = described_class.call(workspace:)

        expect(result.success?).to be true
        expect(result.connectors).not_to be_empty
      end

      it "returns empty when page exceeds available results" do
        result = described_class.call(workspace:, page: 100, per_page: 10)

        expect(result.success?).to be true
        expect(result.connectors).to be_empty
      end
    end
  end
end
