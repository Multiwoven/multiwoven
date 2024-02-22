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

    context "with invalid SQL syntax in query" do
      let(:invalid_inputs) do
        {
          model: {
            connector_id: 1,
            name: "Model Name",
            query: "SELECT FROM table;",
            query_type: "raw_sql",
            primary_key: "id"
          }
        }
      end

      it "fails validation due to invalid SQL syntax" do
        allow(PgQuery).to receive(:parse).with("SELECT FROM table;").and_raise(
          PgQuery::ParseError.new(
            "invalid syntax",
            __FILE__, __LINE__, -1
          )
        )
        result = contract.call(invalid_inputs)
        expect(result.errors[:model][:query]).to include("contains invalid SQL syntax")
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
            query_type: "raw_sql",
            primary_key: "updated_id"
          }
        }
      end

      it "passes validation" do
        allow(PgQuery).to receive(:parse).with("SELECT * FROM updated_table;").and_return(true)
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
