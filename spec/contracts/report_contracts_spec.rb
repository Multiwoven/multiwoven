# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReportContracts::Index do
  subject(:contract) { described_class.new }

  context "with valid parameters" do
    let(:valid_params) do
      {
        type: Reports::ActivityReport::TYPE[:workspace_activity],
        metric: Reports::ActivityReport::METRICS[:total_sync_run_rows],
        connector_id: 1,
        time_period: Reports::ActivityReport::TIME_PERIODS[:one_week]
      }
    end

    it "passes validation" do
      expect(contract.call(valid_params)).to be_success
    end
  end

  context "with missing required parameters" do
    let(:invalid_params) do
      {
        metric: Reports::ActivityReport::METRICS[:total_sync_run_rows],
        connector_id: 1,
        time_period: Reports::ActivityReport::TIME_PERIODS[:one_week]
      }
    end

    it "fails validation" do
      result = contract.call(invalid_params)
      expect(result.errors.to_h).to include(type: ["is missing"])
    end
  end

  context "with invalid type" do
    let(:invalid_params) { { type: "invalid_type" } }

    it "fails validation" do
      result = contract.call(invalid_params)
      expect(result.errors.to_h).to include(type: ["invalid type"])
    end
  end

  context "with invalid metric" do
    let(:invalid_params) { { metric: "invalid_metric" } }

    it "fails validation" do
      result = contract.call(invalid_params)
      expect(result.errors.to_h).to include(metric: ["invalid metric"])
    end
  end

  context "with invalid time period" do
    let(:invalid_params) { { time_period: "invalid_time_period" } }

    it "fails validation" do
      result = contract.call(invalid_params)
      expect(result.errors.to_h).to include(time_period:
      ["invalid time_period. Possible values are 'one_week' or 'one_day'"])
    end
  end

  context "with empty parameters" do
    let(:empty_params) { {} }

    it "fails validation" do
      result = contract.call(empty_params)
      expect(result.errors.to_h.keys).to contain_exactly(:type)
    end
  end
end
