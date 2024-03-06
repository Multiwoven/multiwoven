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

  it { should belong_to(:sync) }
  it { should have_many(:sync_records) }

  describe "enum for status" do
    it {
      should define_enum_for(:status).with_values(%i[pending started querying queued in_progress success paused failed])
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
end
