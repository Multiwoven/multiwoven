# frozen_string_literal: true

require "rails_helper"

RSpec.describe Activities::ExtractorActivity do
  describe "#execute" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let!(:sync) { create(:sync, sync_interval: 3, sync_interval_unit: "hours", source:, destination:) }
    let(:sync_run) { create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model) }
    let(:sync_run_started) do
      create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
    end
    let(:sync_run_querying) do
      create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "querying")
    end
    let(:sync_run_queued) do
      create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "queued")
    end
    let(:extractor_instance) { instance_double("ReverseEtl::Extractors::IncrementalDelta") }
    let(:mock_context) { double("context") }
    let(:activity) { Activities::ExtractorActivity.new(mock_context) }

    before do
      allow(ReverseEtl::Extractors::IncrementalDelta).to receive(:new).and_return(extractor_instance)
      allow(extractor_instance).to receive(:read).with(anything, mock_context)
    end

    it "sync run pending to started" do
      expect(sync_run).to have_state(:pending)
      activity.execute(sync_run.id)
      sync_run.reload
      expect(sync_run).to have_state(:started)
      expect(sync_run.sync_id).to eq(sync.id)
      expect(sync_run.workspace_id).to eq(sync.workspace_id)
      expect(sync_run.source_id).to eq(sync.source_id)
      expect(sync_run.destination_id).to eq(sync.destination_id)
      expect(sync_run.model_id).to eq(sync.model_id)
    end

    it "sync run started to started" do
      expect(sync_run_started).to have_state(:started)
      activity.execute(sync_run_started.id)
      sync_run_started.reload
      expect(sync_run_started).to have_state(:started)
      expect(sync_run_started.sync_id).to eq(sync.id)
      expect(sync_run_started.workspace_id).to eq(sync.workspace_id)
      expect(sync_run_started.source_id).to eq(sync.source_id)
      expect(sync_run_started.destination_id).to eq(sync.destination_id)
      expect(sync_run_started.model_id).to eq(sync.model_id)
    end

    it "sync run querying to started" do
      expect(sync_run_querying).to have_state(:querying)
      activity.execute(sync_run_querying.id)
      sync_run_querying.reload
      expect(sync_run_querying).to have_state(:started)
      expect(sync_run_querying.sync_id).to eq(sync.id)
      expect(sync_run_querying.workspace_id).to eq(sync.workspace_id)
      expect(sync_run_querying.source_id).to eq(sync.source_id)
      expect(sync_run_querying.destination_id).to eq(sync.destination_id)
      expect(sync_run_querying.model_id).to eq(sync.model_id)
    end

    context "when skip loading when status is corrupted" do
      it "sync run state update to queued to start" do
        expect(sync_run_queued).to have_state(:queued)
        activity.execute(sync_run_queued.id)
        sync_run_queued.reload
        expect(sync_run_queued).to have_state(:queued)
      end
    end
  end
end
