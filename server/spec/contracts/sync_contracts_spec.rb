# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SyncContracts" do
  describe SyncContracts::Index do
    subject(:contract) { described_class.new }

    context "with valid page" do
      let(:valid_inputs) { { page: 1 } }

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end
  end

  describe SyncContracts::Show do
    subject(:contract) { described_class.new }

    context "with valid id" do
      let(:valid_inputs) { { id: 1 } }

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end
  end

  describe SyncContracts::Create do
    subject(:contract) { described_class.new }

    let(:valid_inputs) do
      {
        sync: {
          source_id: 1,
          status: "active",
          model_id: 2,
          destination_id: 3,
          schedule_type: "manual",
          sync_interval: 24,
          sync_interval_unit: "hours",
          sync_mode: "full_refresh",
          stream_name: "test_stream",
          configuration: { key: "value" }
        }
      }
    end

    context "with valid inputs" do
      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "with invalid sync mode" do
      let(:invalid_inputs) do
        {
          sync: valid_inputs[:sync].merge(sync_mode: "invalid_mode")
        }
      end

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:sync][:sync_mode]).to include("invalid sync mode")
      end
    end
  end

  describe SyncContracts::Destroy do
    subject(:contract) { described_class.new }

    context "with valid id" do
      let(:valid_inputs) { { id: 1 } }

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end
  end
end
