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
          schedule_type: "interval",
          sync_interval: 24,
          sync_interval_unit: "hours",
          sync_mode: "full_refresh",
          stream_name: "test_stream",
          configuration: { key: "value" }
        }
      }
    end

    context "with valid inputs without name" do
      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "with valid inputs with name" do
      it "passes validation" do
        valid_inputs[:sync][:name] = "sync name"
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

    context "with invalide schedule_type" do
      let(:invalid_inputs) { { sync: valid_inputs[:sync].merge(schedule_type: "automated") } }

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:sync][:schedule_type]).to include("invalid schedule type")
      end
    end

    context "with non-positive sync_interval" do
      let(:invalid_inputs) { { sync: valid_inputs[:sync].merge(sync_interval: 0) } }
      let(:sync_interval_nil) { { sync: valid_inputs[:sync].merge(sync_interval: nil) } }
      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:sync][:sync_interval]).to include("must be greater than 0")
      end

      it "fails validation with nil" do
        result = contract.call(sync_interval_nil)
        expect(result.errors[:sync][:sync_interval]).to include("must be present")
      end
    end

    context "with invalid sync_interval_unit" do
      let(:invalid_inputs) { { sync: valid_inputs[:sync].merge(sync_interval_unit: "min") } }
      let(:sync_interval_unit_nil) { { sync: valid_inputs[:sync].merge(sync_interval_unit: nil) } }

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:sync][:sync_interval_unit]).to include("invalid sync interval unit")
      end
      it "fails validation sync_interval_unit with nil " do
        result = contract.call(sync_interval_unit_nil)
        expect(result.errors[:sync][:sync_interval_unit]).to include("must be present")
      end
    end

    context "with valid cron expression" do
      let(:valid_inputs_cron) do
        { sync: valid_inputs[:sync].merge(schedule_type: "cron_expression", cron_expression: "0 0 */2 * *") }
      end
      let(:invalid_cron) do
        { id: 1, sync: valid_inputs[:sync].merge(schedule_type: "cron_expression", cron_expression: "0 *") }
      end
      it "success validation" do
        result = contract.call(valid_inputs_cron)
        expect(result.errors.messages).to eq([])
      end

      it "invalid validation" do
        result = contract.call(invalid_cron)
        expect(result.errors[:sync][:cron_expression]).to include("invalid cron expression format")
      end
    end
  end

  describe SyncContracts::Update do
    subject(:contract) { described_class.new }

    let(:valid_inputs) do
      {
        id: 1,
        sync: {
          source_id: 1,
          model_id: 2,
          destination_id: 3,
          schedule_type: "interval",
          sync_interval: 15,
          sync_interval_unit: "hours",
          sync_mode: "incremental",
          stream_name: "updated_stream"
        }
      }
    end

    context "with valid inputs" do
      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end
    end

    context "with non-positive sync_interval" do
      let(:invalid_inputs) { { id: 1, sync: valid_inputs[:sync].merge(sync_interval: -1) } }
      let(:sync_interval_nil) { { id: 1, sync: valid_inputs[:sync].merge(sync_interval: nil) } }

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:sync][:sync_interval]).to include("must be greater than 0")
      end
      it "fails validation" do
        result = contract.call(sync_interval_nil)
        expect(result.errors[:sync][:sync_interval]).to include("must be present")
      end
    end
    context "with invalid sync_interval_unit" do
      let(:invalid_inputs) { { sync: valid_inputs[:sync].merge(sync_interval_unit: "min") } }
      let(:sync_interval_unit_nil) { { sync: valid_inputs[:sync].merge(sync_interval_unit: nil) } }

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:sync][:sync_interval_unit]).to include("invalid sync interval unit")
      end
      it "fails validation sync_interval_unit with nil " do
        result = contract.call(sync_interval_unit_nil)
        expect(result.errors[:sync][:sync_interval_unit]).to include("must be present")
      end
    end

    context "with valid cron expression" do
      let(:valid_inputs_cron) do
        { id: 1, sync: valid_inputs[:sync].merge(schedule_type: "cron_expression", cron_expression: "0 0 */2 * *") }
      end
      let(:invalid_cron) do
        { id: 1, sync: valid_inputs[:sync].merge(schedule_type: "cron_expression", cron_expression: "0 invalid") }
      end
      it "success validation" do
        result = contract.call(valid_inputs_cron)
        expect(result.errors.messages).to eq([])
      end

      it "invalid validation" do
        result = contract.call(invalid_cron)
        expect(result.errors[:sync][:cron_expression]).to include("invalid cron expression format")
      end
    end
  end

  describe SyncContracts::Enable do
    subject(:contract) { described_class.new }

    context "with valid parameters " do
      let(:valid_inputs) { { id: 1, enable: true } }
      let(:invalid_inputs) { { id: 1, enable: "disabled" } }

      it "passes validation" do
        expect(contract.call(valid_inputs)).to be_success
      end

      it "fails validation" do
        result = contract.call(invalid_inputs)
        expect(result.errors[:enable]).to include("must be boolean")
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
