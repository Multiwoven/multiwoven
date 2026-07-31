# frozen_string_literal: true

require "rails_helper"

RSpec.describe "EnterpriseEmbedOriginContracts" do
  describe EnterpriseEmbedOriginContracts::Index do
    subject(:contract) { described_class.new }

    it "passes with a valid scope" do
      expect(contract.call(scope: "workspace")).to be_success
      expect(contract.call(scope: "organization")).to be_success
    end

    it "passes when scope is omitted (returns everything)" do
      expect(contract.call({})).to be_success
    end

    it "fails with an unknown scope" do
      result = contract.call(scope: "team")
      expect(result).to be_failure
      expect(result.errors[:scope]).to be_present
    end
  end

  describe EnterpriseEmbedOriginContracts::Create do
    subject(:contract) { described_class.new }

    it "passes with origin + valid scope" do
      expect(contract.call(origin: "https://customer.com", scope: "workspace")).to be_success
    end

    it "fails when origin is missing" do
      result = contract.call(scope: "workspace")
      expect(result).to be_failure
      expect(result.errors[:origin]).to be_present
    end

    it "fails when scope is missing" do
      result = contract.call(origin: "https://customer.com")
      expect(result).to be_failure
      expect(result.errors[:scope]).to be_present
    end

    it "fails when scope is unknown" do
      result = contract.call(origin: "https://customer.com", scope: "team")
      expect(result).to be_failure
      expect(result.errors[:scope]).to be_present
    end
  end

  describe EnterpriseEmbedOriginContracts::Update do
    subject(:contract) { described_class.new }

    it "passes with integer id + origin" do
      expect(contract.call(id: 1, origin: "https://customer.com")).to be_success
    end

    it "fails when id is not an integer" do
      result = contract.call(id: "abc", origin: "https://customer.com")
      expect(result).to be_failure
      expect(result.errors[:id]).to include("must be an integer")
    end

    it "fails when origin is missing" do
      result = contract.call(id: 1)
      expect(result).to be_failure
      expect(result.errors[:origin]).to be_present
    end
  end

  describe EnterpriseEmbedOriginContracts::Destroy do
    subject(:contract) { described_class.new }

    it "passes with an integer id" do
      expect(contract.call(id: 1)).to be_success
    end

    it "fails when id is missing" do
      expect(contract.call({})).to be_failure
    end

    it "fails when id is not an integer" do
      result = contract.call(id: "foo")
      expect(result).to be_failure
      expect(result.errors[:id]).to include("must be an integer")
    end
  end
end
