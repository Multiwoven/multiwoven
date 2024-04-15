# frozen_string_literal: true

require "rails_helper"

module ReverseEtl
  module Utils
    RSpec.describe CursorQueryBuilder do
      describe ".update_query" do
        context "when both cursor_field and current_cursor_field are present" do
          let(:existing_query) { "SELECT * FROM table" }
          let(:source) { create(:connector, connector_type: "source") }
          let(:destination) { create(:connector, connector_type: "destination") }
          let!(:catalog) { create(:catalog, connector: destination) }

          let(:model) { create(:model, connector: source, query: existing_query) }

          let(:sync) do
            create(:sync, model:, source:, destination:, cursor_field: "timestamp", current_cursor_field: "2022-01-01")
          end
          let(:sync_config) { sync.to_protocol }

          it "updates the query with WHERE and ORDER BY clauses" do
            response = described_class.update_query(sync_config)

            expected_query = "(SELECT * FROM table) AS subquery WHERE timestamp >= '2022-01-01' ORDER BY timestamp ASC"
            expect(response.model.query).to eq(expected_query)
          end
        end

        context "when only cursor_field is present" do
          let(:existing_query) { "SELECT * FROM table" }
          let(:source) { create(:connector, connector_type: "source") }
          let(:destination) { create(:connector, connector_type: "destination") }
          let!(:catalog) { create(:catalog, connector: destination) }

          let(:model) { create(:model, connector: source, query: existing_query) }

          let(:sync) do
            create(:sync, model:, source:, destination:, cursor_field: "timestamp")
          end
          let(:sync_config) { sync.to_protocol }

          it "updates the query with only ORDER BY clause" do
            response = described_class.update_query(sync_config)

            expected_query = "(SELECT * FROM table) AS subquery ORDER BY timestamp ASC"
            expect(response.model.query).to eq(expected_query)
          end
        end

        context "when neither cursor_field nor current_cursor_field are present" do
          let(:existing_query) { "SELECT * FROM table" }
          let(:source) { create(:connector, connector_type: "source") }
          let(:destination) { create(:connector, connector_type: "destination") }
          let!(:catalog) { create(:catalog, connector: destination) }

          let(:model) { create(:model, connector: source, query: existing_query) }

          let(:sync) do
            create(:sync, model:, source:, destination:)
          end
          let(:sync_config) { sync.to_protocol }

          it "does not update the query" do
            response = described_class.update_query(sync_config)

            expect(response.model.query).to eq("SELECT * FROM table")
          end
        end
      end
    end
  end
end
