# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ModelContracts" do
  before do
    allow(PgQuery).to receive(:parse).and_return(true)
  end

  describe ModelContracts::Index do
    subject(:contract) { described_class.new }

    context "with valid page" do
      let(:valid_inputs) { { page: 1 } }

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "with invalid page (non-integer)" do
      let(:invalid_inputs) { { page: "first" } }

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:page]).to include("must be an integer")
      end
    end
  end

  describe ModelContracts::Show do
    subject(:contract) { described_class.new }

    context "with valid id" do
      let(:valid_inputs) { { id: 1 } }

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end
  end

  describe ModelContracts::Create do
    subject(:contract) { described_class.new }

    context "with valid inputs" do
      let(:valid_inputs) do
        {
          model: {
            connector_id: 1,
            name: "Model Name",
            query: "SELECT * FROM table;",
            query_type: "raw_sql",
            primary_key: "id"
          }
        }
      end

      let(:valid_input_dynamic_sql) do
        {
          model: {
            connector_id: 1,
            name: "Model Name",
            query: "SELECT * FROM table;",
            query_type: "dynamic_sql",
            primary_key: "id",
            configuration: { "json_schema" => [], "harvesters" => [] }
          }
        }
      end

      let(:valid_input_ai_ml) do
        {
          model: {
            connector_id: 1,
            name: "Model Name",
            query: "SELECT * FROM table;",
            query_type: "dynamic_sql",
            primary_key: "id",
            configuration: { "harvesters" => [] }
          }
        }
      end

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end

      it "passes validation for dynamic_sql query_type" do
        expect(contract.call(valid_input_dynamic_sql)).to be_success
      end

      it "passes validation for ai_ml query_type" do
        expect(contract.call(valid_input_ai_ml)).to be_success
      end
    end

    context "with missing query for query_type requiring it" do
      let(:invalid_inputs) do
        {
          model: {
            connector_id: 1,
            name: "Model Name",
            query_type: "raw_sql",
            primary_key: "id"
          }
        }
      end

      it "fails validation due to missing query" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:model][:query]).to include("Query is required for this query type")
      end
    end

    context "with invalid query_type" do
      let(:invalid_inputs) do
        {
          model: {
            connector_id: 1,
            name: "Model Name",
            query: "SELECT FROM table;",
            query_type: "test",
            primary_key: "id"
          }
        }
      end

      it "fails validation due to invalid query type" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:model][:query_type]).to include("invalid query type")
      end
    end

    context "with query containing LIMIT" do
      let(:invalid_inputs) do
        {
          model: {
            connector_id: 1,
            name: "Model Name",
            query: "SELECT * FROM table LIMIT 10;",
            query_type: "raw_sql",
            primary_key: "id"
          }
        }
      end

      it "fails validation due to LIMIT in query" do
        error_message = "Query validation failed: Query cannot contain LIMIT or OFFSET"
        result = contract.call(invalid_inputs)
        expect(result.errors[:model][:query]).to include(error_message)
      end
    end

    context "with missing or invalid configuration for ai_ml query_type" do
      let(:invalid_inputs) do
        {
          model: {
            connector_id: 1,
            name: "Model Name",
            query_type: "ai_ml",
            primary_key: "id"
          }
        }
      end

      let(:invalid_configuration) do
        {
          model: {
            connector_id: 1,
            name: "Model Name",
            query_type: "ai_ml",
            primary_key: "id",
            configuration: { "test" => "new" }
          }
        }
      end

      it "fails validation due to missing configuration" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:model][:configuration]).to include("Configuration is required for this query type")
      end

      it "fails validation due to invalid configuration" do
        result = contract.call(invalid_configuration)
        expect(result.errors[:model][:configuration]).to include("Config must contain harvester details")
      end
    end

    context "with missing or invalid configuration for dynamic_sql query_type" do
      let(:invalid_inputs) do
        {
          model: {
            connector_id: 1,
            name: "Model Name",
            query_type: "dynamic_sql",
            primary_key: "id"
          }
        }
      end

      let(:invalid_configuration) do
        {
          model: {
            connector_id: 1,
            name: "Model Name",
            query_type: "dynamic_sql",
            primary_key: "id",
            configuration: { "test" => "new" }
          }
        }
      end

      it "fails validation due to missing configuration" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:model][:configuration]).to include("Configuration is required for this query type")
      end

      it "fails validation due to invalid configuration" do
        result = contract.call(invalid_configuration)
        expect(result.errors[:model][:configuration]).to include("Config must contain harvester & json_schema")
      end
    end
  end

  describe ModelContracts::Update do
    subject(:contract) { described_class.new }

    context "with valid inputs" do
      let(:valid_inputs) do
        {
          id: 1,
          model: {
            name: "Updated Model Name",
            query: "SELECT * FROM updated_table;",
            query_type: "soql",
            primary_key: "updated_id"
          }
        }
      end

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "with invalid query_type" do
      let(:invalid_inputs) do
        {
          model: {
            connector_id: 1,
            name: "Model Name",
            query: "SELECT FROM table;",
            query_type: "test",
            primary_key: "id"
          }
        }
      end

      it "fails validation due to invalid query type" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:model][:query_type]).to include("invalid query type")
      end
    end

    context "with query containing LIMIT" do
      let(:invalid_inputs) do
        {
          id: 1,
          model: {
            name: "Updated Model Name",
            query: "SELECT * FROM updated_table LIMIT 10;",
            query_type: "soql",
            primary_key: "updated_id"
          }
        }
      end

      it "fails validation due to LIMIT in query" do
        error_message = "Query validation failed: Query cannot contain LIMIT or OFFSET"
        result = contract.call(invalid_inputs)
        expect(result.errors[:model][:query]).to include(error_message)
      end
    end

    context "with valid inputs without query" do
      let(:valid_inputs) do
        {
          id: 1,
          model: {
            name: "Updated Model Name",
            query_type: "ai_ml",
            primary_key: "updated_id"
          }
        }
      end

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end
  end

  describe ModelContracts::Destroy do
    subject(:contract) { described_class.new }

    context "with valid id" do
      let(:valid_inputs) { { id: 1 } }

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end
  end
end
