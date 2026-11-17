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
    let!(:sync_full_refresh) do
      create(:sync, sync_interval: 3, sync_interval_unit: "hours", source:, destination:, sync_mode: "full_refresh")
    end
    let(:sync_run) { create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model) }
    let(:sync_run_started) do
      create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
    end
    let(:sync_run_querying) do
      create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "querying")
    end
    let(:sync_run_full_refresh_querying) do
      create(:sync_run, sync: sync_full_refresh, workspace: sync_full_refresh.workspace, source:, destination:,
                        model: sync_full_refresh.model, status: "querying")
    end
    let(:sync_run_queued) do
      create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "queued")
    end
    let(:extractor_incremental) { instance_double("ReverseEtl::Extractors::IncrementalDelta") }
    let(:extractor_full_refresh) { instance_double("ReverseEtl::Extractors::FullRefresh") }
    let(:extractor_test) { instance_double("ReverseEtl::Extractors::TestSyncExtractor") }
    let(:extractor_web_scrape) { instance_double("ReverseEtl::Extractors::WebScraping") }
    let(:mock_context) { double("context") }
    let(:activity) { Activities::ExtractorActivity.new(mock_context) }

    before do
      allow(ReverseEtl::Extractors::IncrementalDelta).to receive(:new).and_return(extractor_incremental)
      allow(ReverseEtl::Extractors::FullRefresh).to receive(:new).and_return(extractor_full_refresh)
      allow(ReverseEtl::Extractors::TestSyncExtractor).to receive(:new).and_return(extractor_test)
      allow(ReverseEtl::Extractors::WebScraping).to receive(:new).and_return(extractor_web_scrape)
      allow(extractor_incremental).to receive(:read).with(anything, mock_context)
      allow(extractor_full_refresh).to receive(:read).with(anything, mock_context)
      allow(extractor_test).to receive(:read).with(anything, mock_context)
      allow(extractor_web_scrape).to receive(:read).with(anything, mock_context)
    end

    context "when the source read fails" do
      let(:connector_message) { "connection to server at \"db.example.com\", port 5432 failed: timeout expired" }

      before do
        allow(extractor_incremental).to receive(:read)
          .and_raise(Activities::ExtractorActivity::SourceReadFailed, connector_message)
      end

      it "re-raises the failure" do
        expect { activity.execute(sync_run.id) }.to raise_error(Activities::ExtractorActivity::SourceReadFailed)
      end

      it "leaves the sync run non-terminal so Temporal can retry the read" do
        finished_at_before = sync_run.finished_at

        expect { activity.execute(sync_run.id) }.to raise_error(Activities::ExtractorActivity::SourceReadFailed)
        expect(sync_run.reload).not_to be_terminal_status
        expect(sync_run.finished_at).to eq(finished_at_before)
      end

      it "stores the connector message on the sync run" do
        expect { activity.execute(sync_run.id) }.to raise_error(Activities::ExtractorActivity::SourceReadFailed)
        expect(sync_run.reload.error).to eq(connector_message)
      end

      it "can restart the run on the next attempt" do
        expect { activity.execute(sync_run.id) }.to raise_error(Activities::ExtractorActivity::SourceReadFailed)
        expect(sync_run.reload.may_start?).to be(true)
      end

      it "clears the stored message when a retry starts" do
        expect { activity.execute(sync_run.id) }.to raise_error(Activities::ExtractorActivity::SourceReadFailed)
        allow(extractor_incremental).to receive(:read).with(anything, mock_context)

        activity.execute(sync_run.id)

        expect(sync_run.reload.error).to be_nil
      end

      context "when retries are exhausted and the workflow middleware fails the run" do
        before do
          activity.execute(sync_run.id)
        rescue Activities::ExtractorActivity::SourceReadFailed
          nil
        end

        it "marks the sync run and parent sync failed with finished_at set" do
          sync_run.reload.update_status_post_workflow

          expect(sync_run.reload).to have_state(:failed)
          expect(sync_run.finished_at).to be_present
          expect(sync.reload).to be_failed
        end

        it "queues the sync alert with the connector message already stored" do
          create(:alert, workspace: sync.workspace, alert_sync_failure: true)
          error_seen_by_alert = nil
          allow(SendSyncAlertsJob).to receive(:perform_later) { |id| error_seen_by_alert = SyncRun.find(id).error }

          sync_run.reload.update_status_post_workflow

          expect(error_seen_by_alert).to eq(connector_message)
        end
      end
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

    it "sync run querying to started for incremental" do
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

    it "sync run querying to started for full refresh" do
      expect(sync_run_full_refresh_querying).to have_state(:querying)
      activity.execute(sync_run_full_refresh_querying.id)
      sync_run_full_refresh_querying.reload
      expect(sync_run_full_refresh_querying).to have_state(:started)
      expect(sync_run_full_refresh_querying.sync_id).to eq(sync_full_refresh.id)
      expect(sync_run_full_refresh_querying.workspace_id).to eq(sync_full_refresh.workspace_id)
      expect(sync_run_full_refresh_querying.source_id).to eq(sync_full_refresh.source_id)
      expect(sync_run_full_refresh_querying.destination_id).to eq(sync_full_refresh.destination_id)
      expect(sync_run_full_refresh_querying.model_id).to eq(sync_full_refresh.model_id)
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

  describe "#sync_mode_extractor" do
    let(:sync_run) { instance_double("SyncRun", sync: instance_double("Sync", sync_mode:)) }
    let(:mock_context) { double("context") }
    let(:activity) { Activities::ExtractorActivity.new(mock_context) }

    context "when sync_mode is :incremental" do
      let(:sync_mode) { "incremental" }

      it "returns an instance of IncrementalDelta extractor" do
        extractor = activity.send(:sync_mode_extractor, sync_run.sync.sync_mode.to_sym)
        expect(extractor).to be_a(ReverseEtl::Extractors::IncrementalDelta)
      end
    end

    context "when sync_mode is :full_refresh" do
      let(:sync_mode) { "full_refresh" }

      it "returns an instance of FullRefresh extractor" do
        extractor = activity.send(:sync_mode_extractor, sync_run.sync.sync_mode.to_sym)
        expect(extractor).to be_a(ReverseEtl::Extractors::FullRefresh)
      end
    end

    context "when sync_mode is unsupported" do
      let(:sync_mode) { "unsupported_mode" }

      it "raises an error" do
        expect do
          activity.send(:sync_mode_extractor, sync_run.sync.sync_mode.to_sym)
        end.to raise_error(RuntimeError, "Unsupported sync mode: #{sync_mode}")
      end
    end
  end

  describe "#select_extractor" do
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let!(:sync) { create(:sync, destination:) }
    let(:sync_run) { create(:sync_run, sync:, sync_run_type: "general") }
    let(:sync_run_test) { create(:sync_run, sync:, sync_run_type: "test") }
    let(:mock_context) { double("context") }
    let(:activity) { Activities::ExtractorActivity.new(mock_context) }

    context "when sync_run_type is test" do
      it "returns an instance of TestSyncExtractor" do
        extractor = activity.send(:select_extractor, sync_run_test)
        expect(extractor).to be_a(ReverseEtl::Extractors::TestSyncExtractor)
      end
    end

    context "when sync_run_type is not test in incremental" do
      it "returns an instance of IncrementalDelta extractor for incremental sync_mode" do
        sync.update(sync_mode: "incremental")
        extractor = activity.send(:select_extractor, sync_run)
        expect(extractor).to be_a(ReverseEtl::Extractors::IncrementalDelta)
      end
    end

    context "when sync_run_type is not test in fullrefresh" do
      it "returns an instance of FullRefresh extractor for full_refresh sync_mode" do
        sync.update(sync_mode: "full_refresh")
        extractor = activity.send(:select_extractor, sync_run)
        expect(extractor).to be_a(ReverseEtl::Extractors::FullRefresh)
      end
    end

    context "when sync_run_type is not test in webscraping" do
      it "returns an instance of WebScraping extractor" do
        sync_run.sync.source.update(connector_type: "source", connector_name: "Firecrawl")
        extractor = activity.send(:select_extractor, sync_run)
        expect(extractor).to be_a(ReverseEtl::Extractors::WebScraping)
      end
    end
  end
end
