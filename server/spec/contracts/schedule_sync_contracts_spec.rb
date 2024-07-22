# frozen_string_literal: true

# spec/contracts/schedule_sync_contracts_spec.rb

require "rails_helper"

RSpec.describe ScheduleSyncContracts do
  describe ScheduleSyncContracts::Create do
    subject(:contract) { described_class.new }

    context "when params are valid" do
      let(:params) do
        { schedule_sync: { sync_id: 1 } }
      end

      it "is valid" do
        expect(contract.call(params)).to be_success
      end
    end

    context "when params are invalid" do
      context "when schedule_sync is missing" do
        let(:params) { {} }

        it "is not valid" do
          expect(contract.call(params)).to be_failure
        end

        it "has the correct error message" do
          result = contract.call(params)
          expect(result.errors.to_h).to eq({ schedule_sync: ["is missing"] })
        end
      end

      context "when sync_id is missing" do
        let(:params) { { schedule_sync: {} } }

        it "is not valid" do
          expect(contract.call(params)).to be_failure
        end

        it "has the correct error message" do
          result = contract.call(params)
          expect(result.errors.to_h).to eq({ schedule_sync: { sync_id: ["is missing"] } })
        end
      end

      context "when sync_id is not an integer" do
        let(:params) { { schedule_sync: { sync_id: "not an integer" } } }

        it "is not valid" do
          expect(contract.call(params)).to be_failure
        end

        it "has the correct error message" do
          result = contract.call(params)
          expect(result.errors.to_h).to eq({ schedule_sync: { sync_id: ["must be an integer"] } })
        end
      end
    end
  end

  describe ScheduleSyncContracts::Destroy do
    subject(:contract) { described_class.new }

    context "when params are valid" do
      let(:params) do
        { schedule_sync: { sync_id: 1 } }
      end

      it "is valid" do
        expect(contract.call(params)).to be_success
      end
    end

    context "when params are invalid" do
      context "when schedule_sync is missing" do
        let(:params) { {} }

        it "is not valid" do
          expect(contract.call(params)).to be_failure
        end

        it "has the correct error message" do
          result = contract.call(params)
          expect(result.errors.to_h).to eq({ schedule_sync: ["is missing"] })
        end
      end

      context "when sync_id is missing" do
        let(:params) { { schedule_sync: {} } }

        it "is not valid" do
          expect(contract.call(params)).to be_failure
        end

        it "has the correct error message" do
          result = contract.call(params)
          expect(result.errors.to_h).to eq({ schedule_sync: { sync_id: ["is missing"] } })
        end
      end

      context "when sync_id is not an integer" do
        let(:params) { { schedule_sync: { sync_id: "not an integer" } } }

        it "is not valid" do
          expect(contract.call(params)).to be_failure
        end

        it "has the correct error message" do
          result = contract.call(params)
          expect(result.errors.to_h).to eq({ schedule_sync: { sync_id: ["must be an integer"] } })
        end
      end
    end
  end
end
