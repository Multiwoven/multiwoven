# frozen_string_literal: true

require "rails_helper"

RSpec.describe Alert, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
    it { should have_many(:alert_channels).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:workspace_id) }
    it { should validate_numericality_of(:row_failure_threshold_percent).only_integer.allow_nil }
  end

  describe "#trigger" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let(:sync) { create(:sync, name: "Sync alert test", source:, destination:) }
    let(:success_run) do
      create(:sync_run, sync:, status: :success, total_rows: 100, failed_rows: 30)
    end
    let(:failed_run) { create(:sync_run, sync:, status: :failed) }
    let(:success_alert) do
      create(:alert, alert_sync_success: true, alert_row_failure: true, row_failure_threshold_percent: 10)
    end
    let(:failure_alert) { create(:alert, alert_sync_failure: true) }

    it "should call send_success_alert with sync attributes" do
      alert_medium = create(:alert_medium)
      alert_channel = create(:alert_channel, alert_medium:, alert: success_alert)
      allow(success_alert).to receive(:send_success_alert)
      allow(success_alert).to receive(:send_row_failure_alert)
      success_alert.trigger(success_run)

      expected_attrs_success = {
        name: "Sync alert test",
        end_time: success_run.finished_at,
        duration: success_run.duration_in_seconds,
        sync_id: sync.id,
        sync_run_id: success_run.id,
        error: success_run.error
      }

      expected_attrs_row_failure = expected_attrs_success.merge({ failed_rows_count: 30, total_rows_count: 100 })

      expect(success_alert).to have_received(:send_success_alert).with(expected_attrs_success, alert_channel)
      expect(success_alert).to have_received(:send_row_failure_alert).with(expected_attrs_row_failure, alert_channel)
    end

    it "should call send_failure_alert with sync attributes" do
      alert_medium = create(:alert_medium)
      alert_channel = create(:alert_channel, alert_medium:, alert: failure_alert)
      allow(failure_alert).to receive(:send_failure_alert)
      failure_alert.trigger(failed_run)

      expected_attrs = {
        name: "Sync alert test",
        end_time: failed_run.finished_at,
        duration: failed_run.duration_in_seconds,
        sync_id: sync.id,
        sync_run_id: failed_run.id,
        error: failed_run.error
      }

      expect(failure_alert).to have_received(:send_failure_alert).with(expected_attrs, alert_channel)
    end
  end
end
