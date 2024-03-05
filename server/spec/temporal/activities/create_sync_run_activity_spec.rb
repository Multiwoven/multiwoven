# frozen_string_literal: true

require "rails_helper"

RSpec.describe Activities::CreateSyncRunActivity do
  describe "#execute" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let!(:sync) { create(:sync, sync_interval: 3, sync_interval_unit: "hours", source:, destination:) }
    let(:mock_context) { double("context") }
    let(:activity) { Activities::CreateSyncRunActivity.new(mock_context) }

    context "when no pending SyncRun exists" do
      it "creates a new SyncRun with pending status" do
        expect do
          sync_run_id = activity.execute(sync.id)
          sync_run = SyncRun.find(sync_run_id)
          expect(sync_run).to have_state(:pending)
          expect(sync_run.sync_id).to eq(sync.id)
          expect(sync_run.workspace_id).to eq(sync.workspace_id)
          expect(sync_run.source_id).to eq(sync.source_id)
          expect(sync_run.destination_id).to eq(sync.destination_id)
          expect(sync_run.model_id).to eq(sync.model_id)
        end.to change(SyncRun, :count).by(1)
      end
    end

    context "when a pending SyncRun started exists need to create new with pending" do
      before do
        create(:sync_run, sync:, status: :success)
      end

      it "create a new SyncRun" do
        expect do
          sync_run_id = activity.execute(sync.id)
          sync_run = SyncRun.find(sync_run_id)
          expect(sync_run).to have_state(:pending)
          expect(sync_run.sync_id).to eq(sync.id)
        end.to change(SyncRun, :count).by(1)
      end
    end
  end
end
