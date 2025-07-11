# frozen_string_literal: true

# == Schema Information
#
# Table name: connectors
#
#  id                      :bigint           not null, primary key
#  workspace_id            :integer
#  connector_type          :integer
#  connector_definition_id :integer
#  configuration           :jsonb
#  name                    :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  connector_name          :string
#
require "rails_helper"

RSpec.describe Connector, type: :model do
  subject { described_class.new }

  before do
    allow(subject).to receive(:configuration_schema).and_return({}.to_json)
  end

  context "validations" do
    it { should validate_presence_of(:workspace_id) }
    it { should validate_presence_of(:connector_type) }
    it { should validate_presence_of(:configuration) }
    it { should validate_presence_of(:name) }
  end

  context "associations" do
    it { should belong_to(:workspace) }
    it { should have_many(:models).dependent(:destroy) }
    it { should have_one(:catalog).dependent(:destroy) }
    it {
      is_expected.to have_many(:source_syncs).class_name("Sync")
                                             .with_foreign_key("source_id").dependent(:destroy)
    }
    it {
      is_expected.to have_many(:destination_syncs).class_name("Sync")
                                                  .with_foreign_key("destination_id")
                                                  .dependent(:destroy)
    }
  end

  describe "#to_protocol" do
    it "returns a protocol connector with correct attributes" do
      connector = Connector.new(
        workspace_id: 1,
        connector_type: :source,
        configuration: { key: "value" }.to_json,
        name: "My Connector",
        connector_name: "Snowflake"
      )

      protocol_connector = connector.to_protocol

      expect(protocol_connector).to be_a(Multiwoven::Integrations::Protocol::Connector)
      expect(protocol_connector.name).to eq(connector.connector_name)
      expect(protocol_connector.type).to eq(connector.connector_type)
      expect(protocol_connector.connection_specification).to eq(connector.resolved_configuration)
    end
  end

  describe "#execute_query" do
    let(:workspace) { create(:workspace) } # Assuming you have factories set up for workspace
    let(:connector) do
      create(:connector,
             workspace:,
             connector_type: :source,
             connector_name: "snowflake",
             configuration: { user: "test", password: "password" }) # Adjust attributes as necessary
    end
    let(:client_double) { instance_double("SomeClient") }
    let(:db_connection) { instance_double("SomeDBConnection") }
    let(:query) { "SELECT * FROM users" }
    let(:limited_query) { "#{query} LIMIT 50" }
    let(:query_result) { [{ name: "John Doe" }] }

    before do
      allow(connector).to receive(:connector_client).and_return(client_double)
      allow(client_double).to receive(:new).and_return(client_double)
      allow(client_double).to receive(:create_connection)
        .with(connector.configuration.with_indifferent_access).and_return(db_connection)
      allow(client_double).to receive(:query).with(db_connection, limited_query).and_return(query_result)
    end

    context "when query does not have a LIMIT clause" do
      it "appends a LIMIT clause and executes the query" do
        expect(client_double).to receive(:query).with(db_connection, limited_query).and_return(query_result)
        result = connector.execute_query(query)
        expect(result).to eq(query_result)
      end
    end

    context "when query already has a LIMIT clause" do
      let(:query_with_limit) { "#{query} LIMIT 10" }

      it "executes the query without modifying it" do
        expect(client_double).to receive(:query).with(db_connection, query_with_limit).and_return(query_result)
        result = connector.execute_query(query_with_limit)
        expect(result).to eq(query_result)
      end
    end

    context "with a different limit" do
      let(:custom_limit) { 100 }
      let(:query_with_custom_limit) { "#{query} LIMIT #{custom_limit}" }

      it "appends a custom LIMIT clause if specified" do
        expect(client_double).to receive(:query).with(db_connection, query_with_custom_limit).and_return(query_result)
        result = connector.execute_query(query, limit: custom_limit)
        expect(result).to eq(query_result)
      end
    end
  end

  describe "#default_scope" do
    let(:connector) { create_list(:connector, 4) }

    context "when a multiple connector are created" do
      it "returns the connector in descending order of updated_at" do
        expect(Connector.all).to eq(connector.sort_by(&:updated_at).reverse)
      end
    end

    context "when a connector is updated" do
      it "returns the connector in descending order of updated_at" do
        connector.first.update!(updated_at: DateTime.current + 1.week)
        connector.last.update!(updated_at: DateTime.current - 1.week)

        expect(Connector.all).to eq(connector.sort_by(&:updated_at).reverse)
      end
    end
  end

  describe "#connector_query_type" do
    let(:workspace) { create(:workspace) }
    context "when connector_spec returns nil" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_type: :source,
               connector_name: "snowflake",
               configuration: { user: "test", password: "password" })
      end
      it "returns 'raw_sql'" do
        expect(connector.connector_query_type).to eq("raw_sql")
      end
    end

    context "when connector_spec returns a value" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_type: :source,
               connector_name: "SalesforceConsumerGoodsCloud",
               configuration: { user: "test", password: "password" })
      end
      it "returns the connector_query_type value" do
        expect(connector.connector_query_type).to eq("soql")
      end
    end
  end

  describe "#set_category" do
    let(:workspace) { create(:workspace) }
    let(:connector) do
      create(:connector,
             workspace:)
    end

    context "populate category from connector meta data" do
      it "sets the connector_category based on the meta_data" do
        connector.run_callbacks(:save) { true }
        expect(connector.connector_category).to eq("Marketing Automation")
      end
    end

    context "catagory is set by user" do
      it "does not change the connector_category" do
        connector.update!(connector_category: "user_input_category")
        expect(connector.connector_category).to eq("user_input_category")
      end
    end
  end

  describe ".ai_ml" do
    let!(:ai_ml_connector) { create(:connector, connector_category: "AI Model") }
    let!(:non_ai_ml_connector) { create(:connector, connector_category: "Data Warehouse") }

    it "returns connectors with connector_category in AI_ML_CATEGORIES" do
      result = Connector.ai_ml
      expect(result).to include(ai_ml_connector)
      expect(result).not_to include(non_ai_ml_connector)
    end

    it "check whether connector is ai model or not" do
      expect(ai_ml_connector.ai_model?).to eq(true)
      expect(non_ai_ml_connector.ai_model?).to eq(false)
    end
  end

  describe ".data" do
    let!(:data_connector) { create(:connector, connector_category: "Data Warehouse") }
    let!(:non_data_connector) { create(:connector, connector_category: "AI Model") }

    it "returns connectors with connector_category in DATA_CATEGORIES" do
      result = Connector.data
      expect(result).to include(data_connector)
      expect(result).not_to include(non_data_connector)
    end
  end

<<<<<<< HEAD
=======
  describe "#set_sub_category" do
    let(:workspace) { create(:workspace) }
    let(:connector) do
      create(:connector,
             workspace:)
    end

    context "populate sub_category from connector meta data" do
      it "sets the connector_sub_category based on the meta_data" do
        connector.run_callbacks(:save) { true }
        expect(connector.connector_sub_category).to eq("Relational Database")
      end
    end

    context "catagory is set by user" do
      it "does not change the connector_sub_category" do
        connector.update!(connector_sub_category: "user_input_category")
        expect(connector.connector_sub_category).to eq("user_input_category")
      end
    end
  end

  describe ".ai_ml_service" do
    let!(:ai_ml_connector) do
      create(:connector, connector_category: "AI Model", connector_sub_category: "AI_ML Service")
    end
    let!(:non_ai_ml_connector) do
      create(:connector, connector_category: "Data Warehouse", connector_sub_category: "Relational Database")
    end

    it "returns connectors with connector_sub_category in AI_ML_SERVICE_CATEGORIES" do
      result = Connector.ai_ml_service
      expect(result).to include(ai_ml_connector)
      expect(result).not_to include(non_ai_ml_connector)
    end
  end

  describe ".llm" do
    let!(:ai_ml_connector) { create(:connector, connector_category: "AI Model", connector_sub_category: "LLM") }
    let!(:non_ai_ml_connector) do
      create(:connector, connector_category: "Data Warehouse", connector_sub_category: "Relational Database")
    end

    it "returns connectors with connector_sub_category in LLM_CATEGORIES" do
      result = Connector.llm
      expect(result).to include(ai_ml_connector)
      expect(result).not_to include(non_ai_ml_connector)
    end
  end

  describe ".database" do
    let!(:ai_ml_connector) { create(:connector, connector_category: "AI Model", connector_sub_category: "LLM") }
    let!(:non_ai_ml_connector) do
      create(:connector, connector_category: "Data Warehouse", connector_sub_category: "Relational Database")
    end

    it "returns connectors with connector_sub_category in DATABASE_CATEGORIES" do
      result = Connector.database
      expect(result).not_to include(ai_ml_connector)
      expect(result).to include(non_ai_ml_connector)
    end
  end

  describe ".web" do
    let!(:web_connector) { create(:connector, connector_category: "AI Model", connector_sub_category: "Web Scraper") }
    let!(:non_web_connector) do
      create(:connector, connector_category: "Data Warehouse", connector_sub_category: "Relational Database")
    end

    it "returns connectors with connector_sub_category in WEB_CATEGORIES" do
      result = Connector.web
      expect(result).to include(web_connector)
      expect(result).not_to include(non_web_connector)
    end
  end

  describe ".vector" do
    let!(:vector_connector) do
      create(:connector, connector_category: "AI Model", connector_sub_category: "Vector Database")
    end
    let!(:vector_postgres_connector) do
      create(
        :connector,
        connector_type: "source",
        connector_name: "Postgres",
        configuration: { "data_type": "vector" },
        connector_category: "data",
        connector_sub_category: "Vector Database"
      )
    end
    let!(:non_vector_connector) do
      create(:connector, connector_category: "Data Warehouse", connector_sub_category: "Relational Database")
    end

    it "returns connectors with connector_sub_category in VECTOR_CATEGORIES" do
      result = Connector.vector
      expect(result).to include(vector_connector)
      expect(result).to include(vector_postgres_connector)
      expect(result).not_to include(non_vector_connector)
    end
  end

>>>>>>> 31736261 (chore(CE): Add sub_category fix for postgres (#1224))
  describe "#resolved_configuration" do
    let(:workspace) { create(:workspace) }

    context "when configuration has no ENV variables" do
      let(:connector) do
        create(:connector,
               workspace:,
               configuration: { host: "example.com", port: 5432 })
      end

      it "returns the original configuration" do
        expect(connector.resolved_configuration).to eq(connector.configuration)
      end
    end

    context "when configuration contains ENV variables" do
      let(:connector) do
        create(:connector,
               workspace:,
               configuration: {
                 host: "ENV[\"DB_HOST\"]",
                 password: "ENV[\"DB_PASSWORD\"]",
                 port: 5432
               })
      end

      before do
        ENV["DB_HOST"] = "production.example.com"
        ENV["DB_PASSWORD"] = "secret123"
      end

      after do
        ENV.delete("DB_HOST")
        ENV.delete("DB_PASSWORD")
      end

      it "returns configuration with resolved ENV variables" do
        expected_config = {
          "host" => "production.example.com",
          "password" => "secret123",
          "port" => 5432
        }
        expect(connector.resolved_configuration).to eq(expected_config)
      end
    end
  end
end
