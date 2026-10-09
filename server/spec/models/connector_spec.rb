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

<<<<<<< HEAD
=======
  describe "#generate_response" do
    let(:workspace) { create(:workspace) }
    let(:mock_client) { double("client") }
    let(:mock_response) do
      [
        double("response_item",
               record: double("record",
                              data: {
                                "choices" => [
                                  {
                                    "message" => {
                                      "content" => "Test response"
                                    }
                                  }
                                ]
                              }))
      ]
    end

    context "with OpenAI connector" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_type: :source,
               connector_name: "OpenAI",
               configuration: { "api_key" => "test-key" })
      end

      before do
        allow(connector).to receive(:connector_client).and_return(double(new: mock_client))
      end

      it "handles JSON string payload and converts to Hash" do
        payload_json = {
          "model" => "gpt-4o-mini",
          "messages" => [{ "role" => "user", "content" => "Hello" }]
        }.to_json

        expect(mock_client).to receive(:send).with(
          :run_model,
          anything,
          hash_including("model" => "gpt-4o-mini")
        ).and_return(mock_response)

        result = connector.generate_response(payload_json)
        expect(result).to eq(mock_response)
      end

      it "handles Hash payload as-is" do
        payload_hash = {
          "model" => "gpt-4o-mini",
          "messages" => [{ "role" => "user", "content" => "Hello" }]
        }

        expect(mock_client).to receive(:send).with(
          :run_model,
          anything,
          payload_hash
        ).and_return(mock_response)

        result = connector.generate_response(payload_hash)
        expect(result).to eq(mock_response)
      end
    end

    context "with Anthropic connector" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_type: :source,
               connector_name: "Anthropic",
               configuration: { "api_key" => "test-key" })
      end

      before do
        allow(connector).to receive(:connector_client).and_return(double(new: mock_client))
      end

      it "passes JSON string to Anthropic client" do
        payload_json = {
          "model" => "claude-opus-4-5-20251101",
          "system" => "You are helpful",
          "messages" => [{ "role" => "user", "content" => "Hello" }],
          "max_tokens" => 4096
        }.to_json

        expect(mock_client).to receive(:send).with(
          :run_model,
          anything,
          payload_json
        ).and_return(mock_response)

        result = connector.generate_response(payload_json)
        expect(result).to eq(mock_response)
      end

      it "converts Hash to JSON string for Anthropic client" do
        payload_hash = {
          "model" => "claude-opus-4-5-20251101",
          "system" => "You are helpful",
          "messages" => [{ "role" => "user", "content" => "Hello" }],
          "max_tokens" => 4096
        }

        expect(mock_client).to receive(:send).with(
          :run_model,
          anything,
          payload_hash.to_json
        ).and_return(mock_response)

        result = connector.generate_response(payload_hash)
        expect(result).to eq(mock_response)
      end
    end

    context "with AwsBedrockModel connector" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_type: :source,
               connector_name: "AwsBedrockModel",
               configuration: {
                 "access_key" => "test-key",
                 "secret_access_key" => "test-secret",
                 "region" => "us-east-1"
               })
      end

      before do
        allow(connector).to receive(:connector_client).and_return(double(new: mock_client))
      end

      it "handles JSON string payload and converts to Hash" do
        payload_json = {
          "model" => "anthropic.claude-sonnet-4-20250514-v1:0",
          "system" => "You are helpful",
          "messages" => [{ "role" => "user", "content" => "Hello" }],
          "max_tokens" => 2048
        }.to_json

        expect(mock_client).to receive(:send).with(
          :run_model,
          anything,
          hash_including("model" => "anthropic.claude-sonnet-4-20250514-v1:0")
        ).and_return(mock_response)

        result = connector.generate_response(payload_json)
        expect(result).to eq(mock_response)
      end
    end

    context "with GenericOpenAI connector" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_type: :source,
               connector_name: "GenericOpenAI",
               configuration: {
                 "api_key" => "test-key",
                 "base_url" => "https://api.example.com/v1"
               })
      end

      before do
        allow(connector).to receive(:connector_client).and_return(double(new: mock_client))
      end

      it "handles JSON string payload and converts to Hash" do
        payload_json = {
          "model" => "custom-model-v1",
          "messages" => [{ "role" => "user", "content" => "Hello" }]
        }.to_json

        expect(mock_client).to receive(:send).with(
          :run_model,
          anything,
          hash_including("model" => "custom-model-v1")
        ).and_return(mock_response)

        result = connector.generate_response(payload_json)
        expect(result).to eq(mock_response)
      end
    end

    context "with Aisquared connector (format_llm_payload serializes to JSON)" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_type: :source,
               connector_name: "Aisquared",
               configuration: { "api_key" => "test-key" })
      end

      before do
        allow(connector).to receive(:connector_client).and_return(double(new: mock_client))
      end

      it "passes JSON string to Aisquared client via format_llm_payload" do
        payload_json = {
          "temperature" => 0.7,
          "messages" => [{ "role" => "user", "content" => "Hello" }],
          "max_tokens" => 4096
        }.to_json

        expect(mock_client).to receive(:send).with(
          :run_model,
          anything,
          payload_json
        ).and_return(mock_response)

        result = connector.generate_response(payload_json)
        expect(result).to eq(mock_response)
      end

      it "converts Hash to JSON string for Aisquared client via format_llm_payload" do
        payload_hash = {
          "temperature" => 0.7,
          "messages" => [{ "role" => "user", "content" => "Hello" }],
          "max_tokens" => 4096
        }

        expect(mock_client).to receive(:send).with(
          :run_model,
          anything,
          payload_hash.to_json
        ).and_return(mock_response)

        result = connector.generate_response(payload_hash)
        expect(result).to eq(mock_response)
      end
    end

    context "payload type handling" do
      context "for OpenAI (expects Hash)" do
        let(:connector) do
          create(:connector,
                 workspace:,
                 connector_type: :source,
                 connector_name: "OpenAI",
                 configuration: { "api_key" => "test-key" })
        end

        before do
          allow(connector).to receive(:connector_client).and_return(double(new: mock_client))
        end

        it "passes Hash payload directly to client" do
          payload_hash = { "model" => "gpt-4o", "messages" => [] }

          expect(mock_client).to receive(:send) do |_method, _config, payload_arg|
            expect(payload_arg).to be_a(Hash)
            expect(payload_arg).to eq(payload_hash)
            mock_response
          end

          connector.generate_response(payload_hash)
        end

        it "converts JSON string to Hash for client" do
          payload_json = { "model" => "gpt-4o", "messages" => [] }.to_json

          expect(mock_client).to receive(:send) do |_method, _config, payload_arg|
            expect(payload_arg).to be_a(Hash)
            expect(payload_arg["model"]).to eq("gpt-4o")
            mock_response
          end

          connector.generate_response(payload_json)
        end
      end

      context "for Anthropic (expects JSON string)" do
        let(:connector) do
          create(:connector,
                 workspace:,
                 connector_type: :source,
                 connector_name: "Anthropic",
                 configuration: { "api_key" => "test-key" })
        end

        before do
          allow(connector).to receive(:connector_client).and_return(double(new: mock_client))
        end

        it "converts Hash payload to JSON string for client" do
          payload_hash = { "model" => "claude-opus-4-5-20251101", "messages" => [], "max_tokens" => 4096 }

          expect(mock_client).to receive(:send) do |_method, _config, payload_arg|
            expect(payload_arg).to be_a(String)
            expect(JSON.parse(payload_arg)).to eq(payload_hash)
            mock_response
          end

          connector.generate_response(payload_hash)
        end

        it "keeps JSON string as-is for client" do
          payload_json = { "model" => "claude-opus-4-5-20251101", "messages" => [], "max_tokens" => 4096 }.to_json

          expect(mock_client).to receive(:send) do |_method, _config, payload_arg|
            expect(payload_arg).to be_a(String)
            expect(payload_arg).to eq(payload_json)
            mock_response
          end

          connector.generate_response(payload_json)
        end
      end
    end

    context "for Aisquared (format_llm_payload expects JSON string)" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_type: :source,
               connector_name: "Aisquared",
               configuration: { "api_key" => "test-key" })
      end

      before do
        allow(connector).to receive(:connector_client).and_return(double(new: mock_client))
      end

      it "converts Hash payload to JSON string for Aisquared via format_llm_payload" do
        payload_hash = {
          "temperature" => 0.7,
          "messages" => [{ "role" => "user", "content" => "Hello" }],
          "max_tokens" => 4096
        }

        expect(mock_client).to receive(:send) do |_method, _config, payload_arg|
          expect(payload_arg).to be_a(String)
          expect(JSON.parse(payload_arg)).to eq(payload_hash)
          mock_response
        end

        connector.generate_response(payload_hash)
      end

      it "keeps JSON string as-is for Aisquared via format_llm_payload" do
        payload_json = {
          "temperature" => 0.7,
          "messages" => [{ "role" => "user", "content" => "Hello" }],
          "max_tokens" => 4096
        }.to_json

        expect(mock_client).to receive(:send) do |_method, _config, payload_arg|
          expect(payload_arg).to be_a(String)
          expect(payload_arg).to eq(payload_json)
          mock_response
        end

        connector.generate_response(payload_json)
      end
    end

    context "error handling" do
      let(:connector) do
        create(:connector,
               workspace:,
               connector_type: :source,
               connector_name: "OpenAI",
               configuration: { "api_key" => "test-key" })
      end

      before do
        allow(connector).to receive(:connector_client).and_return(double(new: mock_client))
      end

      it "raises ArgumentError with context for malformed JSON" do
        expect do
          connector.generate_response("not valid json")
        end.to raise_error(ArgumentError, /Invalid JSON payload for OpenAI/)
      end

      it "raises ArgumentError with context for incomplete JSON" do
        expect do
          connector.generate_response('{"model": "gpt-4"')
        end.to raise_error(ArgumentError, /Invalid JSON payload for OpenAI/)
      end

      it "includes provider name in error message for Anthropic" do
        anthropic_connector = create(:connector,
                                     workspace:,
                                     connector_type: :source,
                                     connector_name: "Anthropic",
                                     configuration: { "api_key" => "test-key" })
        allow(anthropic_connector).to receive(:connector_client).and_return(double(new: mock_client))

        expect do
          anthropic_connector.generate_response("invalid json")
        end.to raise_error(ArgumentError, /Invalid JSON payload for Anthropic/)
      end

      it "includes provider name in error message for Aisquared" do
        aisquared_connector = create(:connector,
                                     workspace:,
                                     connector_type: :source,
                                     connector_name: "Aisquared",
                                     configuration: { "api_key" => "test-key" })
        allow(aisquared_connector).to receive(:connector_client).and_return(double(new: mock_client))

        expect do
          aisquared_connector.generate_response("invalid json")
        end.to raise_error(ArgumentError, /Invalid JSON payload for Aisquared/)
      end
    end
  end

>>>>>>> 5a003b41e (chore(CE): Server Gem Update 0.36.0 (#1939))
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

  describe "#execute_search" do
    let(:workspace) { create(:workspace) } # Assuming you have factories set up for workspace
    let(:connector) do
      create(
        :connector,
        connector_type: "source",
        connector_name: "PineconeDB",
        configuration: {
          region: "us-east-1",
          api_key: "fake_api_key",
          index_name: "test",
          namespace: "test_vectors"
        }
      )
    end

    let(:client_instance) { Multiwoven::Integrations::Source::PineconeDB::Client.new }

    let(:pinecone_client) { double("Pinecone::Client") }
    let(:pinecone_index) { double("Pinecone::Index") }
    let(:pinecone_response) do
      double("Pinecone::Response", body: {
        matches: [
          {
            score: 0.95,
            metadata: { name: "John Doe" }
          }
        ]
      }.to_json)
    end

    let(:query_result) { { "score" => 0.95, "metadata" => { "name" => "John Doe" } } }

    before do
      allow(Multiwoven::Integrations::Source::PineconeDB::Client).to receive(:new) do
        instance = Multiwoven::Integrations::Source::PineconeDB::Client.allocate
        instance.instance_variable_set(:@index_name, "test")
        instance.instance_variable_set(:@namespace, "test_vectors")
        instance
      end

      allow_any_instance_of(Multiwoven::Integrations::Source::PineconeDB::Client)
        .to receive(:create_connection)
        .and_return(pinecone_client)

      allow(pinecone_client).to receive(:index).with("test").and_return(pinecone_index)
      allow(pinecone_index).to receive(:query).and_return(pinecone_response)

      allow(connector).to receive(:connector_client)
        .and_return(Multiwoven::Integrations::Source::PineconeDB::Client)
    end

    context "when vector and limit" do
      it "executes the vector search" do
        vector = [0.1, 0.2, 0.3]
        limit = 1
        result = connector.execute_search(vector, limit)
        expect(result[0].record.data).to eq(query_result)
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

  let(:workspace) { create(:workspace) }
  let(:connector) { create(:connector, workspace:) }

  describe "#masked_configuration" do
    let(:mock_client) { double("connector_client") }
    let(:mock_spec) do
      {
        connection_specification: {
          properties: {
            host: { type: "string", title: "Host" },
            credentials: {
              type: "object",
              properties: {
                username: { type: "string", title: "Username" },
                password: { type: "string", title: "Password", multiwoven_secret: true }
              }
            },
            api_key: { type: "string", title: "API Key", multiwoven_secret: true }
          }
        }
      }
    end

    before do
      allow(connector).to receive(:connector_client).and_return(double(new: mock_client))
      allow(mock_client).to receive(:connector_spec).and_return(mock_spec)
    end

    context "when configuration has secrets" do
      let(:configuration) do
        {
          "host" => "example.com",
          "credentials" => {
            "username" => "user",
            "password" => "secret123"
          },
          "api_key" => "key123"
        }
      end

      before do
        connector.configuration = configuration
      end

      it "masks secret values with asterisks" do
        result = connector.masked_configuration

        expect(result["host"]).to eq("example.com")
        expect(result["credentials"]["username"]).to eq("user")
        expect(result["credentials"]["password"]).to eq("*************")
        expect(result["api_key"]).to eq("*************")
      end

      it "does not modify the original configuration" do
        original_config = connector.configuration.deep_dup
        connector.masked_configuration

        expect(connector.configuration).to eq(original_config)
      end
    end

    context "when configuration has no secrets" do
      let(:configuration) do
        {
          "host" => "example.com",
          "port" => "5432",
          "database" => "test_db"
        }
      end

      before do
        connector.configuration = configuration
      end

      it "returns configuration unchanged" do
        result = connector.masked_configuration

        expect(result).to eq(configuration)
      end
    end

    context "when configuration has nested objects without secrets" do
      let(:configuration) do
        {
          "host" => "example.com",
          "options" => {
            "timeout" => 30,
            "retries" => 3
          }
        }
      end

      before do
        connector.configuration = configuration
      end

      it "preserves nested structure" do
        result = connector.masked_configuration

        expect(result["host"]).to eq("example.com")
        expect(result["options"]["timeout"]).to eq(30)
        expect(result["options"]["retries"]).to eq(3)
      end
    end

    context "when configuration has arrays" do
      let(:configuration) do
        {
          "hosts" => %w[host1 host2],
          "credentials" => {
            "username" => "user",
            "password" => "secret123"
          }
        }
      end

      before do
        connector.configuration = configuration
      end

      it "preserves arrays and masks secrets" do
        result = connector.masked_configuration

        expect(result["hosts"]).to eq(%w[host1 host2])
        expect(result["credentials"]["username"]).to eq("user")
        expect(result["credentials"]["password"]).to eq("*************")
      end
    end
  end

  describe "#extract_secret_keys" do
    let(:schema) do
      {
        properties: {
          host: { type: "string" },
          credentials: {
            type: "object",
            properties: {
              username: { type: "string" },
              password: { type: "string", multiwoven_secret: true }
            }
          },
          api_key: { type: "string", multiwoven_secret: true },
          nested: {
            type: "object",
            properties: {
              secret: { type: "string", multiwoven_secret: true },
              normal: { type: "string" }
            }
          }
        }
      }
    end

    it "extracts all secret keys from schema" do
      result = connector.send(:extract_secret_keys, schema)

      expect(result).to contain_exactly("password", "api_key", "secret")
    end

    context "when schema has no secrets" do
      let(:schema) do
        {
          properties: {
            host: { type: "string" },
            port: { type: "number" }
          }
        }
      end

      it "returns empty array" do
        result = connector.send(:extract_secret_keys, schema)

        expect(result).to be_empty
      end
    end

    context "when schema is not a hash" do
      it "returns empty array" do
        result = connector.send(:extract_secret_keys, "not a hash")

        expect(result).to be_empty
      end
    end

    context "when schema has no properties" do
      let(:schema) { { type: "object" } }

      it "returns empty array" do
        result = connector.send(:extract_secret_keys, schema)

        expect(result).to be_empty
      end
    end
  end

  describe "#mask_secret_values" do
    let(:secret_keys) { %w[password api_key] }

    context "when config is a hash" do
      let(:config) do
        {
          "host" => "example.com",
          "password" => "secret123",
          "credentials" => {
            "username" => "user",
            "password" => "secret456"
          }
        }
      end

      it "masks secret values and preserves structure" do
        result = connector.send(:mask_secret_values, config, secret_keys)

        expect(result["host"]).to eq("example.com")
        expect(result["password"]).to eq("*************")
        expect(result["credentials"]["username"]).to eq("user")
        expect(result["credentials"]["password"]).to eq("*************")
      end
    end

    context "when config is an array" do
      let(:config) do
        [
          { "name" => "item1", "password" => "secret1" },
          { "name" => "item2", "api_key" => "key2" }
        ]
      end

      it "masks secrets in array items" do
        result = connector.send(:mask_secret_values, config, secret_keys)

        expect(result[0]["name"]).to eq("item1")
        expect(result[0]["password"]).to eq("*************")
        expect(result[1]["name"]).to eq("item2")
        expect(result[1]["api_key"]).to eq("*************")
      end
    end

    context "when config is not a hash or array" do
      it "returns config unchanged" do
        result = connector.send(:mask_secret_values, "string_value", secret_keys)

        expect(result).to eq("string_value")
      end
    end

    context "when no secrets match" do
      let(:config) do
        {
          "host" => "example.com",
          "port" => "5432"
        }
      end

      it "returns config unchanged" do
        result = connector.send(:mask_secret_values, config, secret_keys)

        expect(result).to eq(config)
      end
    end
  end
end
