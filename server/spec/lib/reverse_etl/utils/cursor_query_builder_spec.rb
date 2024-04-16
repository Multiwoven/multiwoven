# frozen_string_literal: true

require "rails_helper"

module ReverseEtl
  module Utils
    RSpec.describe CursorQueryBuilder do
      let(:existing_query) { "SELECT * FROM table" }
      let(:source) { create(:connector, connector_type: "source", connector_name: "Snowflake") }
      let(:source_salesforce) do
        create(:connector, connector_type: "source", connector_name: "SalesforceConsumerGoodsCloud")
      end
      let(:destination) { create(:connector, connector_type: "destination") }
      let!(:catalog) { create(:catalog, connector: destination) }
      let(:model) { create(:model, connector: source, query: existing_query) }
      let(:model_salesforce) { create(:model, connector: source, query: existing_query) }

      describe ".build_cursor_query" do
        context "when both cursor_field and current_cursor_field are present" do
          let(:sync) do
            create(:sync, model:, source:, destination:, cursor_field: "timestamp", current_cursor_field: "2022-01-01")
          end

          let(:sync_salesforce) do
            create(:sync, model: model_salesforce, source: source_salesforce, destination:, cursor_field: "timestamp",
                          current_cursor_field: "2022-01-01")
          end
          let(:sync_config) { sync.to_protocol }
          let(:sync_config_salesforce) { sync_salesforce.to_protocol }

          it "updates the query for raw_sql query type with WHERE and ORDER BY clauses" do
            query = described_class.build_cursor_query(sync_config, "2022-01-01")

            expected_query = "SELECT * FROM table AS subquery WHERE timestamp >= '2022-01-01' ORDER BY timestamp ASC"
            expect(query).to eq(expected_query)
          end

          it "updates the query for soql query type with WHERE and ORDER BY clauses" do
            query = described_class.build_cursor_query(sync_config_salesforce, "2022-01-01")

            expected_query = "SELECT * FROM table AS subquery WHERE timestamp >= 2022-01-01 ORDER BY timestamp ASC"
            expect(query).to eq(expected_query)
          end
        end

        context "when only cursor_field is present" do
          let(:sync) do
            create(:sync, model:, source:, destination:, cursor_field: "timestamp")
          end
          let(:sync_salesforce) do
            create(:sync, model: model_salesforce, source: source_salesforce, destination:, cursor_field: "timestamp")
          end
          let(:sync_config) { sync.to_protocol }
          let(:sync_config_salesforce) { sync_salesforce.to_protocol }

          it "updates the query for raw_sql query type with only ORDER BY clause" do
            query = described_class.build_cursor_query(sync_config, nil)

            expected_query = "SELECT * FROM table AS subquery ORDER BY timestamp ASC"
            expect(query).to eq(expected_query)
          end

          it "updates the query for soql query type with only ORDER BY clause" do
            query = described_class.build_cursor_query(sync_config_salesforce, nil)

            expected_query = "SELECT * FROM table AS subquery ORDER BY timestamp ASC"
            expect(query).to eq(expected_query)
          end
        end

        context "when neither cursor_field nor current_cursor_field are present" do
          let(:sync) do
            create(:sync, model:, source:, destination:)
          end
          let(:sync_config) { sync.to_protocol }
          it "does not update the query" do
            query = described_class.build_cursor_query(sync_config, nil)

            expect(query).to eq(nil)
          end
        end
      end
    end
  end
end
