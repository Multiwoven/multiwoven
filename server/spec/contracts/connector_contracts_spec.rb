# frozen_string_literal: true

require "rails_helper"

describe ConnectorContracts::Create do
  subject(:contract) { described_class.new }

  context "when valid inputs are provided" do
    let(:valid_inputs) do
      {
        connector: {
          name: "Example Connector",
          connector_name: "Snowflake",
          connector_type: "source",
          configuration: { test: "test" }
        }
      }
    end

    it "passes validation" do
      expect(contract.call(valid_inputs)).to be_success
    end
  end

  context "when invalid connector type is provided" do
    let(:invalid_inputs) do
      {
        connector: {
          name: "Example Connector",
          connector_name: "invalid_source",
          connector_type: "invalid_type",
          configuration: {}
        }
      }
    end

    it "fails validation" do
      result = contract.call(invalid_inputs)
      expect(result.errors[:connector][:connector_type]).to include("invalid connector type")
    end
  end
end

describe ConnectorContracts::QuerySource do
  subject(:contract) { described_class.new }

  context "when query contains valid SQL syntax" do
    let(:valid_inputs) { { id: 1, query: "SELECT * FROM users" } }

    it "passes validation" do
      expect(contract.call(valid_inputs)).to be_success
    end
  end
end

describe ConnectorContracts::Discover do
  subject(:contract) { described_class.new }

  context "when id is provided and valid" do
    let(:valid_inputs) { { id: 1 } }

    it "passes validation" do
      expect(contract.call(valid_inputs)).to be_success
    end
  end

  context "when id is not provided" do
    let(:invalid_inputs) { {} } # Omitting :id

    it "fails validation" do
      result = contract.call(invalid_inputs)
      expect(result.errors[:id]).to include("is missing")
    end
  end

  context "when id is not an integer" do
    let(:invalid_inputs) { { id: "a" } } # Non-integer :id

    it "fails validation" do
      result = contract.call(invalid_inputs)
      expect(result.errors[:id]).to include("must be an integer")
    end
  end
end

describe ConnectorContracts::Destroy do
  subject(:contract) { described_class.new }

  context "when id is provided and valid" do
    let(:valid_inputs) { { id: 1 } }

    it "passes validation" do
      expect(contract.call(valid_inputs)).to be_success
    end
  end

  context "when id is not provided" do
    let(:invalid_inputs) { {} }

    it "fails validation" do
      result = contract.call(invalid_inputs)
      expect(result.errors[:id]).to include("is missing")
    end
  end

  context "when id is not an integer" do
    let(:invalid_inputs) { { id: "a" } }

    it "fails validation" do
      result = contract.call(invalid_inputs)
      expect(result.errors[:id]).to include("must be an integer")
    end
  end
end

describe ConnectorContracts::Update do
  subject(:contract) { described_class.new }

  context "when valid inputs are provided" do
    let(:valid_inputs) do
      {
        id: 1,
        connector: {
          name: "New Connector Name",
          connector_name: "Snowflake",
          connector_type: "source",
          configuration: { key: "value" }
        }
      }
    end

    it "passes validation" do
      expect(contract.call(valid_inputs)).to be_success
    end
  end

  context "when optional fields are provided but invalid" do
    let(:invalid_inputs) do
      {
        id: 1,
        connector: {
          name: "",
          connector_name: "invalid_source",
          connector_type: "invalid_type",
          configuration: {}
        }
      }
    end

    it "fails validation due to multiple errors" do
      result = contract.call(invalid_inputs)
      expect(result).to_not be_success
      expect(result.errors[:connector][:name]).to include("must be filled")
      expect(result.errors[:connector][:connector_type]).to include("invalid connector type")
    end
  end

  context "when id is not an integer" do
    let(:invalid_inputs) { { id: "a", connector: { name: "Valid Name" } } }

    it "fails validation" do
      result = contract.call(invalid_inputs)
      expect(result.errors[:id]).to include("must be an integer")
    end
  end

  context "when connector_type is valid but connector_name is invalid for the type" do
    let(:inputs_with_invalid_name_for_type) do
      {
        id: 1,
        connector: {
          connector_type: "source",
          connector_name: "invalid_source_name"
        }
      }
    end

    it "fails validation due to invalid connector source name" do
      result = contract.call(inputs_with_invalid_name_for_type)
      expect(result).to_not be_success
      expect(result.errors[:connector][%i[connector_type connector_name]]).to include("invalid connector source name")
    end
  end
end

describe ConnectorContracts::ExecuteModel do
  subject(:contract) { described_class.new }

  context "when payload contains valid payload" do
    let(:valid_inputs) do
      {
        id: 1,
        payload: '{"model":"gpt-4o-mini",' \
                 '"messages":[{"role":"user","content":"Hi"}],' \
                 '"stream":false}'
      }
    end

    it "passes validation" do
      expect(contract.call(valid_inputs)).to be_success
    end
  end

  context "when payload contains invalid payload" do
    let(:valid_inputs) do
      {
        id: 1,
        payload: "Hello"
      }
    end

    it "fail validation" do
      result = contract.call(valid_inputs)
      expect(result).to_not be_success
      expect(result.errors[:payload]).to include("must be a valid JSON string")
    end
  end
end
