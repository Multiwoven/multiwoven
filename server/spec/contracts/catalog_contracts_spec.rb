# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogContracts::Create do
  subject(:contract) { described_class.new }

  describe "validations" do
    context "when valid parameters are provided" do
      let(:valid_params) do
        {
          connector_id: 1,
          catalog: {
            json_schema: {
              type: "object",
              properties: {
                name: { type: "string" }
              },
              required: ["name"]
            }
          }
        }
      end

      it "passes validation" do
        result = contract.call(valid_params)
        expect(result).to be_success
      end
    end

    context "when connector_id is missing" do
      let(:invalid_params) do
        {
          catalog: {
            json_schema: {
              type: "object",
              properties: {
                name: { type: "string" }
              },
              required: ["name"]
            }
          }
        }
      end

      it "fails validation" do
        result = contract.call(invalid_params)
        expect(result).to_not be_success
        expect(result.errors[:connector_id]).to include("is missing")
      end
    end

    context "when catalog is missing" do
      let(:invalid_params) do
        {
          connector_id: 1
        }
      end

      it "fails validation" do
        result = contract.call(invalid_params)
        expect(result).to_not be_success
        expect(result.errors[:catalog]).to include("is missing")
      end
    end

    context "when json_schema is missing" do
      let(:invalid_params) do
        {
          connector_id: 1,
          catalog: {}
        }
      end

      it "fails validation" do
        result = contract.call(invalid_params)
        expect(result).to_not be_success
        expect(result.errors[:catalog][:json_schema]).to include("is missing")
      end
    end

    context "when json_schema is not a hash" do
      let(:invalid_params) do
        {
          connector_id: 1,
          catalog: {
            json_schema: "invalid_schema"
          }
        }
      end

      it "fails validation" do
        result = contract.call(invalid_params)
        expect(result).to_not be_success
        expect(result.errors[:catalog][:json_schema]).to include("must be a hash")
      end
    end
  end
end
