# frozen_string_literal: true

require "spec_helper"

RSpec.describe Middlewares::UpdateSyncRunStatusMiddleware do
  let(:source) do
    create(:connector, connector_type: "source", connector_name: "Snowflake")
  end
  let(:destination) { create(:connector, connector_type: "destination") }
  let!(:catalog) { create(:catalog, connector: destination) }
  let!(:sync) { create(:sync, source:, destination:, status: "pending", workflow_id: 1) }
  let!(:sync_run) { create(:sync_run, sync:, workflow_run_id: 1) }
  let(:middleware) { described_class.new }
  let(:metadata) { double("metadata", to_h: { "workflow_run_id" => 1 }) }

  before do
    allow(Temporal.logger).to receive(:info)
    allow(Temporal.logger).to receive(:error)
  end

  context "updates sync run status if not in terminal state" do
    it "updates syn_run and sync status to failure after workflow execution" do
      middleware.call(metadata) {}
      expect(sync_run.reload.status).to eq("failed")
      expect(sync.reload.status).to eq("failed")
    end
  end
end
