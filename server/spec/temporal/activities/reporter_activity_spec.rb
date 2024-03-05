# frozen_string_literal: true

require "rails_helper"

RSpec.describe Activities::ReporterActivity do
  describe "#execute" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let!(:sync) { create(:sync, sync_interval: 3, sync_interval_unit: "hours", source:, destination:) }
    let!(:sync_run_progress) do
      create(:sync_run, sync:, source:, destination:, status: "in_progress")
    end
    let!(:sync_run_queued) do
      create(:sync_run, sync:, source:, destination:, status: "queued")
    end
    let(:mock_context) { double("context") }
    let(:activity) { Activities::ReporterActivity.new(mock_context) }
    it "SyncRun state in_prograss to success" do
      expect(sync_run_progress).to have_state(:in_progress)
      activity.execute(sync_run_progress.id)
      sync_run_progress.reload
      expect(sync_run_progress).to have_state(:success)
      expect(sync_run_progress.sync).to have_state(:healthy)
    end

    it "SyncRun fail when state queued to success" do
      expect(sync_run_queued).to have_state(:queued)
      activity.execute(sync_run_queued.id)
      sync_run_queued.reload
      expect(sync_run_queued).to have_state(:queued)
    end
  end
end
