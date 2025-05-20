# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncRun, type: :model do
  it { should validate_presence_of(:sync_id) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:total_query_rows) }
  it { should validate_presence_of(:total_rows) }
  it { should validate_presence_of(:successful_rows) }
  it { should validate_presence_of(:failed_rows) }
  it { should validate_presence_of(:workspace_id) }
  it { should validate_presence_of(:source_id) }
  it { should validate_presence_of(:destination_id) }
  it { should validate_presence_of(:model_id) }
  it { should validate_presence_of(:sync_run_type) }

  it { should belong_to(:sync) }
  it { should have_many(:sync_records) }
  it { should have_many(:sync_files) }
  describe "enum for status" do
    it {
      should define_enum_for(:status).with_values(%i[pending started querying queued in_progress success paused failed
                                                     canceled])
    }
  end

  describe "#set_defaults" do
    let(:new_sync_run) { SyncRun.new }

    it "sets default values" do
      expect(new_sync_run.status).to eq("pending")
      expect(new_sync_run.total_query_rows).to eq(0)
      expect(new_sync_run.total_rows).to eq(0)
      expect(new_sync_run.successful_rows).to eq(0)
      expect(new_sync_run.failed_rows).to eq(0)
    end
  end

  describe "AASM states" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let(:sync) { create(:sync, sync_interval: 3, sync_interval_unit: "hours", source:, destination:) }
    let(:sync_run) { create(:sync_run, sync:) }

    it "starts in pending state" do
      expect(sync_run).to have_state(:pending)
    end

    context "state transitions" do
      it "transitions from pending to started" do
        sync_run.start
        expect(sync_run).to have_state(:started)
      end

      it "transitions from started to querying" do
        sync_run.start
        sync_run.query
        expect(sync_run).to have_state(:querying)
      end

      it "transitions from querying to queued" do
        sync_run.start
        sync_run.query
        sync_run.queue
        expect(sync_run).to have_state(:queued)
      end

      it "transitions from queued to in_progress" do
        sync_run.start
        sync_run.query
        sync_run.queue
        sync_run.progress
        expect(sync_run).to have_state(:in_progress)
      end

      it "transitions from in_progress to success" do
        sync_run.start
        sync_run.query
        sync_run.queue
        sync_run.progress
        sync_run.complete
        expect(sync_run).to have_state(:success)
      end

      it "transitions from any applicable state to failed" do
        sync_run.start
        sync_run.abort
        expect(sync_run).to have_state(:failed)
      end

      it "transitions from any applicable state to canceled" do
        sync_run.start

        sync_run.cancel
        expect(sync_run).to have_state(:canceled)
      end
    end

    context "when transition is not allowed" do
      it "does not transition from started to  directly" do
        sync_run.start
        expect(sync_run).to have_state(:started)
        expect do
          sync_run.complete
        end.to raise_error(AASM::InvalidTransition)
        expect(sync_run).to have_state(:started)
      end
    end
  end

  describe "#discard" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let!(:sync) { create(:sync, sync_interval: 3, sync_interval_unit: "hours", source:, destination:) }
    let!(:sync1) { create(:sync, sync_interval: 3, sync_interval_unit: "hours", source:, destination:) }
    let!(:sync_run_discard) { create(:sync_run, sync:) }
    let!(:sync_run) { create(:sync_run, sync: sync1) }
    let!(:sync_record) do
      create(:sync_record, sync:, sync_run: sync_run_discard, fingerprint: "unique_fingerprint", primary_key: "key1")
    end

    before do
      sync.discard
    end

    it "excludes discarded records from default queries" do
      sync_run_discard.reload
      expect(SyncRun.discarded).to be_empty
      expect(SyncRun.with_discarded.discarded).to include(sync_run_discard)
      expect(SyncRun.all).not_to include(sync_run_discard)
    end

    it "allows accessing discarded records through unscoped or discarded" do
      sync_run_discard.reload
      sync_run.reload
      sync.reload
      expect(SyncRun.unscoped).to include(sync_run, sync_run_discard)
      expect(SyncRun.with_discarded.discarded).to include(sync_run_discard)
    end

    it "discards all associated sync_runs" do
      sync_run_discard.reload
      sync_run.reload
      expect(sync_run_discard.discarded_at).not_to be_nil
      expect(sync_run.discarded_at).to be_nil
    end

    it "calls the perform_post_discard_sync_run method" do
      sync_record.reload
      expect(sync_record.sync_run_id).to be_nil
    end
  end

  describe "#terminal_status?" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let!(:sync) { create(:sync, source:, destination:) }
    let!(:sync_run_success) { create(:sync_run, sync:, status: "success") }
    let!(:sync_run_pending) { create(:sync_run, sync:, status: "pending") }

    it "returns true if sync run is in terminal status" do
      expect(sync_run_success.terminal_status?).to be(true)
      expect(sync_run_pending.terminal_status?).to be(false)
    end
  end

  describe "#update_failure" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let!(:sync) { create(:sync, source:, destination:, status: "pending") }
    let!(:sync_run_pending) { create(:sync_run, sync:, status: "pending") }

    it "updates sync_run status and sync status to failure" do
      sync_run_pending.update_failure!
      expect(sync_run_pending.status).to eq("failed")
      expect(sync.status).to eq("failed")
    end
  end

  describe "#update_status_post_workflow" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let!(:sync) { create(:sync, source:, destination:, status: "pending") }
    let!(:sync_run_pending) { create(:sync_run, sync:, status: "pending") }
    let!(:sync_run_success) { create(:sync_run, sync:, status: "success") }

    it "updates sync_run status and sync status to failure after workflow if not in terminal state" do
      sync_run_pending.finished_at = nil
      sync_run_pending.update_status_post_workflow
      expect(sync_run_pending.status).to eq("failed")
      expect(sync_run_pending.finished_at).not_to be_nil
      expect(sync.status).to eq("failed")
    end

    it "does not updates sync_run status and sync status if in terminal state" do
      sync_run_success.update_status_post_workflow
      expect(sync_run_success.status).to eq("success")
    end
  end

  describe "#send_status_email" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let(:sync) { create(:sync, sync_interval: 3, sync_interval_unit: "hours", source:, destination:) }
    let(:sync_run) { create(:sync_run, sync:, status: :pending) }

    it "calls send_status_email after commit when status changes to failed" do
      allow(sync_run).to receive(:send_status_email)
      sync_run.update!(status: :failed)
      expect(sync_run).to have_received(:send_status_email)
    end

    it "does not call send_status_email if status does not change to success or failed" do
      allow(sync_run).to receive(:send_status_email)
      sync_run.update!(status: :in_progress)
      expect(sync_run).not_to have_received(:send_status_email)
    end
  end

  describe "scopes" do
    describe ".active" do
      let(:source) do
        create(:connector, connector_type: "source", connector_name: "Snowflake")
      end
      let(:destination) { create(:connector, connector_type: "destination") }
      let!(:catalog) { create(:catalog, connector: destination) }
      let(:sync) { create(:sync, sync_interval: 3, sync_interval_unit: "hours", source:, destination:) }

      let!(:pending_run) { create(:sync_run, sync:, status: :pending) }
      let!(:started_run) { create(:sync_run, sync:, status: :started) }
      let!(:querying_run) { create(:sync_run, sync:, status: :querying) }
      let!(:queued_run) { create(:sync_run, sync:, status: :queued) }
      let!(:in_progress_run) { create(:sync_run, sync:, status: :in_progress) }
      let!(:success_run) { create(:sync_run, sync:, status: :success) }
      let!(:paused_run) { create(:sync_run, sync:, status: :paused) }
      let!(:failed_run) { create(:sync_run, sync:, status: :failed) }
      let!(:canceled_run) { create(:sync_run, sync:, status: :canceled) }

      it "returns only active sync runs" do
        active_runs = SyncRun.active
        expect(active_runs).to include(pending_run, started_run, querying_run, queued_run, in_progress_run)
        expect(active_runs).not_to include(success_run, paused_run, failed_run, canceled_run)
      end
    end
  end

  describe "sync_run_type" do
    it "defines sync_run_type enum with specified values" do
      expect(SyncRun.sync_run_types).to eq({ "general" => 0, "test" => 1 })
    end
  end

  describe "active_alerts?" do
    let(:workspace) { create(:workspace) }
    let(:source) do
      create(:connector, workspace:, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, workspace:, connector_type: "destination") }
    let!(:catalog) { create(:catalog, workspace:, connector: destination) }
    let(:sync) { create(:sync, source:, destination:, workspace:) }
    let!(:sync_run) { create(:sync_run, sync:, workspace:) }

    it "returns false if not alerts are present for the current workspace" do
      expect(sync_run.active_alerts?).to be(false)
    end

    it "returns true if alerts are present for the current workspace" do
      create(:alert, workspace:, alert_sync_success: true)
      expect(sync_run.active_alerts?).to be(true)
    end
  end

  describe "#queue_sync_alert" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let(:sync) { create(:sync, source:, destination:) }
    let(:sync_run) { create(:sync_run, sync:, status: :pending) }

    it "calls queue_sync_alert after commit when status changes to failed" do
      allow(sync_run).to receive(:queue_sync_alert)
      sync_run.update!(status: :failed)
      expect(sync_run).to have_received(:queue_sync_alert)
    end

    it "does not call queue_sync_alert if status does not change" do
      allow(sync_run).to receive(:queue_sync_alert)
      sync_run.update!(total_rows: 100)
      expect(sync_run).not_to have_received(:queue_sync_alert)
    end
  end

  describe "#row_failure_percent" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let(:sync) { create(:sync, source:, destination:) }
    let(:sync_run) { create(:sync_run, sync:, status: :success, total_rows: 100, failed_rows: 30) }

    it "calculates and returns the row failure percentage" do
      expect(sync_run.row_failure_percent).to eq(30.0)
    end
  end

  describe "#duration_in_seconds" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let(:sync) { create(:sync, source:, destination:) }
    now = Time.zone.now
    let(:sync_run) { create(:sync_run, sync:, status: :success, finished_at: now, started_at: now - 100.seconds) }

    it "calculates and returns the duration in seconds" do
      expect(sync_run.duration_in_seconds).to eq(100)
    end
  end

  describe "#track_usage" do
    let(:organization) { create(:organization) }
    let(:workspace) { create(:workspace, organization:) }
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let(:sync) { create(:sync, source:, destination:) }
    let(:plan) { create(:billing_plan) }
    let(:subscription) { create(:billing_subscription, organization:, plan:, status: 1) }
    let(:sync_run) { create(:sync_run, workspace:, sync:, successful_rows: 0) }

    it "increments rows_synced when successful_rows changes from 0 to a positive value" do
      expect(subscription.rows_synced).to eq(1)
      sync_run.update!(successful_rows: 100)
      subscription.reload
      expect(subscription.rows_synced).to eq(101)
    end

    it "does not increment rows_synced if successful_rows was already positive" do
      sync_run.update!(successful_rows: 5)
      expect(subscription).not_to receive(:increment!)
      sync_run.update!(successful_rows: 10)
    end
  end
end
