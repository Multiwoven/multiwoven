# frozen_string_literal: true

require "rails_helper"

module ReverseEtl
  module Utils # rubocop:disable Metrics/ModuleLength
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

            expected_query = "SELECT * FROM (SELECT * FROM table) AS subquery " \
                             "WHERE timestamp >= '2022-01-01' ORDER BY timestamp ASC"
            expect(query).to eq(expected_query)
          end

          it "escapes single quotes in the raw_sql cursor value" do
            query = described_class.build_cursor_query(sync_config, "O'Brien")

            expect(query).to eq(
              "SELECT * FROM (SELECT * FROM table) AS subquery " \
              "WHERE timestamp >= 'O''Brien' ORDER BY timestamp ASC"
            )
          end

          it "updates the query for soql query type with WHERE and ORDER BY clauses" do
            query = described_class.build_cursor_query(sync_config_salesforce, "2022-01-01")

            expected_query = "SELECT * FROM table WHERE timestamp >= 2022-01-01 ORDER BY timestamp ASC"
            expect(query).to eq(expected_query)
          end

          it "leaves soql datetime cursor values unquoted" do
            query = described_class.build_cursor_query(
              sync_config_salesforce,
              "2022-01-01T12:30:00Z"
            )

            expect(query).to include("WHERE timestamp >= 2022-01-01T12:30:00Z")
            expect(query).not_to include("'2022-01-01T12:30:00Z'")
          end

          it "quotes and escapes soql string cursor values" do
            allow(sync_config_salesforce).to receive(:cursor_field).and_return("Account.Name__c")

            query = described_class.build_cursor_query(sync_config_salesforce, "O'Brien")

            expect(query).to eq(
              "SELECT * FROM table WHERE Account.Name__c >= 'O''Brien' ORDER BY Account.Name__c ASC"
            )
          end

          it "quotes crafted soql cursor values so they cannot alter the predicate" do
            query = described_class.build_cursor_query(
              sync_config_salesforce,
              "2022-01-01 OR Name != null"
            )

            expect(query).to include("WHERE timestamp >= '2022-01-01 OR Name != null'")
            expect(query).not_to match(/WHERE timestamp >= 2022-01-01 OR Name/)
          end
        end

        context "when both cursor_field and not current_cursor_field are present soql complex query" do
          let(:sales_query) do
            "SELECT Id, User.Username, RecordType.Name, Account.AccountNumber, " \
            "Account.OnboardedAccountNumber__c, PlannedVisitStartTime, PlannedVisitEndTime FROM Visit " \
            "WHERE RecordType.Name = 'Picture of Success Visit' " \
            "AND ((Account.AccountNumber != null AND Account.AccountNumber != '') " \
            "OR (Account.OnboardedAccountNumber__c != null AND Account.OnboardedAccountNumber__c != ''))"
          end
          let(:model_sales) { create(:model, connector: source, query: sales_query) }
          let(:sync_salesforce) do
            create(:sync, model: model_sales, source: source_salesforce, destination:, cursor_field: "timestamp")
          end
          let(:sync_config_salesforce) { sync_salesforce.to_protocol }
          it "updates the query for soql query type with WHERE and ORDER BY clauses" do
            query = described_class.build_cursor_query(sync_config_salesforce, nil)

            expected_query = "SELECT Id, User.Username, RecordType.Name, Account.AccountNumber, " \
            "Account.OnboardedAccountNumber__c, PlannedVisitStartTime, PlannedVisitEndTime FROM Visit " \
            "WHERE RecordType.Name = 'Picture of Success Visit' " \
            "AND ((Account.AccountNumber != null AND Account.AccountNumber != '') " \
            "OR (Account.OnboardedAccountNumber__c != null AND Account.OnboardedAccountNumber__c != '')) " \
                             "ORDER BY timestamp ASC"
            expect(query).to eq(expected_query)
          end
        end

        context "when both cursor_field and current_cursor_field are present soql complex query" do
          let(:sales_query) do
            "SELECT Id, User.Username, RecordType.Name, Account.AccountNumber, " \
            "Account.OnboardedAccountNumber__c, PlannedVisitStartTime, PlannedVisitEndTime FROM Visit " \
            "WHERE RecordType.Name = 'Picture of Success Visit' " \
            "AND ((Account.AccountNumber != null AND Account.AccountNumber != '') " \
            "OR (Account.OnboardedAccountNumber__c != null AND Account.OnboardedAccountNumber__c != ''))"
          end
          let(:model_sales) { create(:model, connector: source, query: sales_query) }
          let(:sync_salesforce) do
            create(:sync, model: model_sales, source: source_salesforce, destination:, cursor_field: "timestamp",
                          current_cursor_field: "2022-01-01")
          end
          let(:sync_config_salesforce) { sync_salesforce.to_protocol }
          it "updates the query for soql query type with WHERE and ORDER BY clauses" do
            query = described_class.build_cursor_query(sync_config_salesforce, "2022-01-01")

            expected_query = "SELECT Id, User.Username, RecordType.Name, Account.AccountNumber, " \
            "Account.OnboardedAccountNumber__c, PlannedVisitStartTime, PlannedVisitEndTime FROM Visit " \
            "WHERE RecordType.Name = 'Picture of Success Visit' " \
            "AND ((Account.AccountNumber != null AND Account.AccountNumber != '') " \
            "OR (Account.OnboardedAccountNumber__c != null AND Account.OnboardedAccountNumber__c != '')) "\
            "AND timestamp >= 2022-01-01 ORDER BY timestamp ASC"
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

            expected_query = "SELECT * FROM (SELECT * FROM table) AS subquery ORDER BY timestamp ASC"
            expect(query).to eq(expected_query)
          end

          it "strips a trailing semicolon before wrapping the query" do
            model.update!(query: "SELECT * FROM table;")
            query = described_class.build_cursor_query(sync.reload.to_protocol, nil)

            expect(query).to eq(
              "SELECT * FROM (SELECT * FROM table) AS subquery ORDER BY timestamp ASC"
            )
            expect(query).not_to include("table;)")
          end

          it "strips trailing whitespace and semicolon before wrapping the query" do
            model.update!(query: "SELECT * FROM table;  \n")
            query = described_class.build_cursor_query(sync.reload.to_protocol, nil)

            expect(query).to eq(
              "SELECT * FROM (SELECT * FROM table) AS subquery ORDER BY timestamp ASC"
            )
          end

          it "updates the query for soql query type with only ORDER BY clause" do
            query = described_class.build_cursor_query(sync_config_salesforce, nil)

            expected_query = "SELECT * FROM table ORDER BY timestamp ASC"
            expect(query).to eq(expected_query)
          end
        end

        context "when neither cursor_field nor current_cursor_field are present" do
          let(:sync) do
            create(:sync, model:, source:, destination:)
          end
          let(:sync_config) { sync.to_protocol }

          it "returns the original query unchanged" do
            query = described_class.build_cursor_query(sync_config, nil)

            expect(query).to eq(existing_query)
          end
        end

        context "when cursor_field is blank" do
          let(:sync) do
            create(:sync, model:, source:, destination:, cursor_field: "")
          end
          let(:sync_config) { sync.to_protocol }

          it "returns the original query without wrapping or ORDER BY" do
            query = described_class.build_cursor_query(sync_config, "2022-01-01")

            expect(query).to eq(existing_query)
            expect(query).not_to include("AS subquery")
            expect(query).not_to include("ORDER BY")
          end
        end

        context "when query_type is unsupported" do
          let(:sync) do
            create(:sync, model:, source:, destination:, cursor_field: "timestamp")
          end
          let(:sync_config) { sync.to_protocol }

          it "returns the original query instead of nil" do
            allow(sync_config.source).to receive(:query_type).and_return("http")

            query = described_class.build_cursor_query(sync_config, "2022-01-01")

            expect(query).to eq(existing_query)
            expect(query).not_to be_nil
          end
        end

        context "when cursor_field is not a safe identifier" do
          let(:sync) do
            create(:sync, model:, source:, destination:, cursor_field: "timestamp")
          end
          let(:sync_config) { sync.to_protocol }
          let(:sync_salesforce) do
            create(:sync, model: model_salesforce, source: source_salesforce, destination:,
                          cursor_field: "timestamp")
          end
          let(:sync_config_salesforce) { sync_salesforce.to_protocol }

          it "raises ArgumentError instead of interpolating malicious SQL" do
            allow(sync_config).to receive(:cursor_field).and_return("job; DROP TABLE users--")

            expect do
              described_class.build_cursor_query(sync_config, "A-100")
            end.to raise_error(ArgumentError, /Invalid cursor_field/)
          end

          it "rejects quoted or spaced identifiers" do
            allow(sync_config).to receive(:cursor_field).and_return('"Last Name"')

            expect do
              described_class.build_cursor_query(sync_config, nil)
            end.to raise_error(ArgumentError, /Invalid cursor_field/)
          end

          it "allows a simple column name for raw_sql sources" do
            allow(sync_config).to receive(:cursor_field).and_return("job_component_key")

            query = described_class.build_cursor_query(sync_config, nil)

            expect(query).to include("ORDER BY job_component_key ASC")
          end

          it "allows dotted/qualified names for raw_sql sources" do
            allow(sync_config).to receive(:cursor_field).and_return("schema.job")

            query = described_class.build_cursor_query(sync_config, "A-100")

            expect(query).to include("ORDER BY schema.job ASC")
            expect(query).to include("WHERE schema.job >= 'A-100'")
          end

          it "allows dotted Salesforce-style field paths for soql sources" do
            allow(sync_config_salesforce).to receive(:cursor_field)
              .and_return("Account.OnboardedAccountNumber__c")

            query = described_class.build_cursor_query(sync_config_salesforce, nil)

            expect(query).to include("ORDER BY Account.OnboardedAccountNumber__c ASC")
          end
        end

        context "when the model query is a CTE" do
          let(:cte_query) do
            <<~SQL.squish
              WITH RECURSIVE up AS (
                SELECT b.component_job, b.parent_job, b.parent_job AS root_job, 1 AS depth
                FROM jobboss.bill_of_jobs b
              )
              SELECT component_job || '|' || parent_job AS job_component_key, component_job, parent_job
              FROM up
            SQL
          end
          let(:model) { create(:model, connector: source, query: cte_query) }
          let(:sync) do
            create(:sync, model:, source:, destination:, cursor_field: "job_component_key")
          end
          let(:sync_config) { sync.to_protocol }

          it "wraps the CTE so ORDER BY applies to the result set" do
            query = described_class.build_cursor_query(sync_config, nil)

            expect(query).to eq(
              "SELECT * FROM (#{cte_query}) AS subquery ORDER BY job_component_key ASC"
            )
          end
        end

        context "when the model query uses GROUP BY aggregates" do
          let(:aggregate_query) do
            <<~SQL.squish
              SELECT
                d.job,
                min(d.requested_date) AS requested_date,
                min(d.promised_date) AS promised_date,
                max(d.shipped_date) AS shipped_date
              FROM jobboss.delivery d
              WHERE d.job NOT LIKE '__-__98%'
                AND d.job NOT LIKE '__-__99%'
              GROUP BY d.job
            SQL
          end
          let(:model) { create(:model, connector: source, query: aggregate_query) }
          let(:sync) do
            create(:sync, model:, source:, destination:, cursor_field: "job",
                          current_cursor_field: "A-100")
          end
          let(:sync_config) { sync.to_protocol }

          it "wraps the aggregation so cursor WHERE/ORDER BY are not appended onto GROUP BY" do
            query = described_class.build_cursor_query(sync_config, "A-100")

            expect(query).to eq(
              "SELECT * FROM (#{aggregate_query}) AS subquery " \
              "WHERE job >= 'A-100' ORDER BY job ASC"
            )
            # Old bug: "... GROUP BY d.job AS subquery ORDER BY ..."
            expect(query).not_to match(/GROUP BY d\.job AS subquery/i)
          end
        end
      end
    end
  end
end
