# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserContracts::Me do
  subject(:contract) { described_class.new }

  describe "validations" do
    context "when id is provided" do
      let(:result) { contract.call(id:) }

      context "and id is an integer" do
        let(:id) { 1 }

        it "is successful" do
          expect(result).to be_success
          expect(result.errors.to_h).to be_empty
        end
      end

      context "and id is not an integer" do
        let(:id) { "a" }

        it "fails" do
          expect(result).to_not be_success
          expect(result.errors.to_h.keys).to include(:id)
          expect(result.errors.to_h[:id]).to include("must be an integer")
        end
      end
    end

    context "when id is not provided" do
      let(:result) { contract.call({}) }

      it "is successful because id is optional" do
        expect(result).to be_success
        expect(result.errors.to_h).to be_empty
      end
    end
  end
end
