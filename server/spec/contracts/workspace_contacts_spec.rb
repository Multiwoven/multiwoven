# frozen_string_literal: true

require "rails_helper"

RSpec.describe "WorkspaceContracts" do
  describe WorkspaceContracts::Update do
    subject(:contract) { described_class.new }

    let(:valid_inputs) do
      {
        id: 1,
        workspace: {
          name: "Workspace Test",
          organization_id: 1,
          region: "us-east-1"
        }
      }
    end

    context "with valid inputs" do
      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "with invalid workspace name" do
      let(:invalid_inputs) do
        {
          id: 1,
          workspace: {
            name: "-------",
            organization_id: 1,
            region: "us-east-1"
          }
        }
      end

      it "fails validation with consecutive hyphens" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:workspace][:name]).to include("cannot contain consecutive hyphens")
      end
    end

    context "with invalid workspace name" do
      let(:invalid_inputs) do
        {
          id: 1,
          workspace: {
            name: "-",
            organization_id: 1,
            region: "us-east-1"
          }
        }
      end

      it "fails validation with consecutive hyphens" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:workspace][:name]).to include("must contain at least one letter")
      end
    end
  end
end
