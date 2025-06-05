# frozen_string_literal: true

require "rails_helper"

module ReverseEtl
  module Utils
    RSpec.describe RandomQueryBuilder do
      let(:existing_query) { "SELECT * FROM table" }
      let(:source) { create(:connector, connector_type: "source", connector_name: "Snowflake") }
      let(:source_bigquery) { create(:connector, connector_type: "source", connector_name: "Bigquery") }
      let(:source_intuitquickbooks) { create(:connector, connector_type: "source", connector_name: "IntuitQuickBooks") }
      let(:source_salesforce) do
        create(:connector, connector_type: "source", connector_name: "SalesforceConsumerGoodsCloud")
      end
      let(:destination) { create(:connector, connector_type: "destination") }
      let!(:catalog) { create(:catalog, connector: destination) }
      let(:model) { create(:model, connector: source, query: existing_query) }
      let(:model_salesforce) { create(:model, connector: source, query: existing_query) }

      describe ".build_random_record_query" do
        context "when query_type is raw_sql" do
          let(:sync) do
            create(:sync, model:, source:, destination:)
          end
          let(:sync_config) { sync.to_protocol }

          it "returns the query with ORDER BY RANDOM()" do
            query = described_class.build_random_record_query(sync_config)

            expected_query = "SELECT * FROM (#{existing_query}) AS subquery ORDER BY RANDOM()"
            expect(query).to eq(expected_query)
          end
        end

        context "when query_type is raw_sql and source is BigQuery" do
          let(:sync) do
            create(:sync, model:, source: source_bigquery, destination:)
          end
          let(:sync_config) { sync.to_protocol }

          it "returns the query with ORDER BY RAND()" do
            query = described_class.build_random_record_query(sync_config)

            expected_query = "SELECT * FROM (#{existing_query}) AS subquery ORDER BY RAND()"
            expect(query).to eq(expected_query)
          end
        end

        context "when query_type is raw_sql and source is Intuit QuickBooks" do
          let(:sync) do
            create(:sync, model:, source: source_intuitquickbooks, destination:)
          end
          let(:sync_config) { sync.to_protocol }

          it "returns the query" do
            query = described_class.build_random_record_query(sync_config)

            expected_query = existing_query
            expect(query).to eq(expected_query)
          end
        end

        context "when query_type is soql" do
          let(:sync_salesforce) do
            create(:sync, model: model_salesforce, source: source_salesforce, destination:)
          end
          let(:sync_config_salesforce) { sync_salesforce.to_protocol }

          it "returns the query" do
            query = described_class.build_random_record_query(sync_config_salesforce)
            expect(query).to eq(existing_query)
          end
        end

        context "when query_type is not specified" do
          let(:sync) do
            create(:sync, model:, source:, destination:)
          end
          let(:sync_config) { sync.to_protocol }

          it "assumes raw_sql and returns the query with ORDER BY RANDOM()" do
            query = described_class.build_random_record_query(sync_config)

            expected_query = "SELECT * FROM (#{existing_query}) AS subquery ORDER BY RANDOM()"
            expect(query).to eq(expected_query)
          end
        end
      end
    end
  end
end
