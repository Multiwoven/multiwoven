# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ConnectorDefinitionContracts" do
  before do
    stub_const("Multiwoven::Integrations::Protocol::ConnectorType",
               { "source" => "source", "destination" => "destination" })
    stub_const("Multiwoven::Integrations::ENABLED_SOURCES", ["valid_source"])
    stub_const("Multiwoven::Integrations::ENABLED_DESTINATIONS", ["valid_destination"])
  end

  describe ConnectorDefinitionContracts::Index do
    subject(:contract) { described_class.new }

    context "with valid type and page" do
      let(:valid_inputs) { { type: "source", page: 1 } }

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "with invalid connector type" do
      let(:invalid_inputs) { { type: "invalid_type" } }

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:type]).to include("invalid connector type")
      end
    end
  end

  describe ConnectorDefinitionContracts::Show do
    subject(:contract) { described_class.new }

    context "with valid id and type" do
      let(:valid_inputs) { { id: "123", type: "source" } }

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "with invalid connector type" do
      let(:invalid_inputs) { { id: "123", type: "invalid_type" } }

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:type]).to include("invalid connector type")
      end
    end
  end

  describe ConnectorDefinitionContracts::CheckConnection do
    subject(:contract) { described_class.new }

    context "with valid inputs" do
      let(:valid_inputs) do
        {
          name: "valid_source",
          type: "source",
          connection_spec: { key: "value" }
        }
      end

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "with invalid connector type" do
      let(:invalid_inputs) do
        {
          name: "valid_source",
          type: "invalid_type",
          connection_spec: { key: "value" }
        }
      end

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:type]).to include("invalid connector type")
      end
    end

    context "with invalid connector name for type" do
      let(:invalid_inputs) do
        {
          name: "invalid_source",
          type: "source",
          connection_spec: { key: "value" }
        }
      end

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:name]).to include("invalid connector source name")
      end
    end
  end
end
