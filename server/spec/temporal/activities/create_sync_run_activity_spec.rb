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
    let(:metadata) { double("metadata") }
    let(:activity) { Activities::CreateSyncRunActivity.new(mock_context) }

    context "when no pending SyncRun exists" do
      it "creates a new SyncRun with type general and pending status" do
        allow(metadata).to receive(:workflow_run_id).and_return(1)
        allow(mock_context).to receive(:metadata).and_return(metadata)
        expect do
          sync_run_id = activity.execute(sync.id, "general")
          sync_run = SyncRun.find(sync_run_id)
          expect(sync_run).to have_state(:pending)
          expect(sync_run.sync_id).to eq(sync.id)
          expect(sync_run.workspace_id).to eq(sync.workspace_id)
          expect(sync_run.source_id).to eq(sync.source_id)
          expect(sync_run.destination_id).to eq(sync.destination_id)
          expect(sync_run.model_id).to eq(sync.model_id)
          expect(sync_run.sync_run_type).to eq("general")
        end.to change(SyncRun, :count).by(1)
      end

      it "creates a new SyncRun with type test and pending status" do
        expect do
          allow(metadata).to receive(:workflow_run_id).and_return(1)
          allow(mock_context).to receive(:metadata).and_return(metadata)
          sync_run_id = activity.execute(sync.id, "test")
          sync_run = SyncRun.find(sync_run_id)
          expect(sync_run).to have_state(:pending)
          expect(sync_run.sync_id).to eq(sync.id)
          expect(sync_run.workspace_id).to eq(sync.workspace_id)
          expect(sync_run.source_id).to eq(sync.source_id)
          expect(sync_run.destination_id).to eq(sync.destination_id)
          expect(sync_run.model_id).to eq(sync.model_id)
          expect(sync_run.sync_run_type).to eq("test")
        end.to change(SyncRun, :count).by(1)
      end
    end

    context "when a pending SyncRun started exists need to create new with pending" do
      before do
        create(:sync_run, sync:, status: :success)
      end

      it "create a new SyncRun" do
        allow(metadata).to receive(:workflow_run_id).and_return(1)
        allow(mock_context).to receive(:metadata).and_return(metadata)
        expect do
          sync_run_id = activity.execute(sync.id, "general")
          sync_run = SyncRun.find(sync_run_id)
          expect(sync_run).to have_state(:pending)
          expect(sync_run.sync_id).to eq(sync.id)
        end.to change(SyncRun, :count).by(1)
      end
    end
  end
end
