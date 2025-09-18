# frozen_string_literal: true

require "rails_helper"

RSpec.describe Middlewares::UpdateSyncRunStatusMiddleware do
  let(:source) do
    create(:connector, connector_type: "source", connector_name: "Snowflake")
  end
  let(:destination) { create(:connector, connector_type: "destination") }
  let!(:catalog) { create(:catalog, connector: destination) }
  let!(:sync) { create(:sync, source:, destination:, status: "pending", workflow_id: 1) }
  let!(:sync_run) do
    run = create(:sync_run, sync:, workflow_run_id: 1)
    run.update!(status: "in_progress")
    run
  end
  let(:middleware) { described_class.new }
  let(:sync_workflow_metadata) do
    double("metadata", to_h: { "workflow_name" => "Workflows::SyncWorkflow", "workflow_run_id" => 1 })
  end
  let(:other_workflow_metadata) do
    double("metadata", to_h: { "workflow_name" => "Workflows::OtherWorkflow", "workflow_run_id" => 1 })
  end

  before do
    allow(Rails.logger).to receive(:info)
  end

  describe "#call" do
    context "when workflow is Workflows::SyncWorkflow" do
      context "when sync_run is found" do
        it "logs the status before updating and calls update_status_post_workflow" do
          expected_log_message = {
            message: "UpdateSyncRunStatusMiddleware::call status before sync_run&.update_status_post_workflow",
            sync_run_id: sync_run.id,
            status: "in_progress"
          }.to_s

          expect(Rails.logger).to receive(:info).with(expected_log_message)

          middleware.call(sync_workflow_metadata) {}

          expect(sync_run.reload.status).to eq("failed")
          expect(sync.reload.status).to eq("failed")
        end

        it "yields the block" do
          block_called = false
          middleware.call(sync_workflow_metadata) { block_called = true }
          expect(block_called).to be true
        end
      end

      context "when sync_run is not found" do
        let(:sync_workflow_metadata) do
          double("metadata", to_h: { "workflow_name" => "Workflows::SyncWorkflow", "workflow_run_id" => 999 })
        end

        it "does not log and does not raise an error" do
          expect(Rails.logger).not_to receive(:info)
          expect { middleware.call(sync_workflow_metadata) {} }.not_to raise_error
        end

        it "still yields the block" do
          block_called = false
          middleware.call(sync_workflow_metadata) { block_called = true }
          expect(block_called).to be true
        end
      end
    end

    context "when workflow is not Workflows::SyncWorkflow" do
      it "does not log and does not update sync_run status" do
        expect(Rails.logger).not_to receive(:info)

        middleware.call(other_workflow_metadata) {}

        expect(sync_run.reload.status).to eq("in_progress")
        expect(sync.reload.status).to eq("pending")
      end

      it "still yields the block" do
        block_called = false
        middleware.call(other_workflow_metadata) { block_called = true }
        expect(block_called).to be true
      end
    end
  end
end
