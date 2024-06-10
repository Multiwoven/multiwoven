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

      it "passes validation" do
        allow(PgQuery).to receive(:parse).with("SELECT * FROM table;").and_return(true)
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

    context "with query containing OFFSET" do
      let(:invalid_inputs) do
        {
          model: {
            connector_id: 1,
            name: "Model Name",
            query: "SELECT * FROM table OFFSET 10;",
            query_type: "raw_sql",
            primary_key: "id"
          }
        }
      end

      it "fails validation due to OFFSET in query" do
        error_message = "Query validation failed: Query cannot contain LIMIT or OFFSET"
        result = contract.call(invalid_inputs)
        expect(result.errors[:model][:query]).to include(error_message)
      end
    end

    context "with query containing LIMIT and OFFSET" do
      let(:invalid_inputs) do
        {
          model: {
            connector_id: 1,
            name: "Model Name",
            query: "SELECT * FROM table LIMIT 10 OFFSET 5;",
            query_type: "raw_sql",
            primary_key: "id"
          }
        }
      end

      it "fails validation due to LIMIT and OFFSET in query" do
        error_message = "Query validation failed: Query cannot contain LIMIT or OFFSET"
        result = contract.call(invalid_inputs)
        expect(result.errors[:model][:query]).to include(error_message)
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

    context "with query containing OFFSET" do
      let(:invalid_inputs) do
        {
          id: 1,
          model: {
            name: "Updated Model Name",
            query: "SELECT * FROM updated_table OFFSET 10;",
            query_type: "soql",
            primary_key: "updated_id"
          }
        }
      end

      it "fails validation due to OFFSET in query" do
        error_message = "Query validation failed: Query cannot contain LIMIT or OFFSET"
        result = contract.call(invalid_inputs)
        expect(result.errors[:model][:query]).to include(error_message)
      end
    end

    context "with query containing LIMIT and OFFSET" do
      let(:invalid_inputs) do
        {
          id: 1,
          model: {
            name: "Updated Model Name",
            query: "SELECT * FROM updated_table LIMIT 10 OFFSET 5;",
            query_type: "soql",
            primary_key: "updated_id"
          }
        }
      end

      it "fails validation due to LIMIT and OFFSET in query" do
        error_message = "Query validation failed: Query cannot contain LIMIT or OFFSET"
        result = contract.call(invalid_inputs)
        expect(result.errors[:model][:query]).to include(error_message)
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
