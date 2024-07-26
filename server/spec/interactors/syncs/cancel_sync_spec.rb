# frozen_string_literal: true

require "rails_helper"

RSpec.describe Syncs::CancelSync do
  let(:workspace) { create(:workspace) }
  let(:source) { create(:connector, workspace:) }
  let(:destination) { create(:connector, workspace:) }
  let(:model) { create(:model, workspace:, connector: source) }
  let(:sync) do
    create(:sync, id: 30, status: 1, workspace:, source:, destination:, model:,
                  workflow_id: "klaviyo-klaviyo-syncid-30",
                  schedule_type: "manual")
  end

  before do
    create(:catalog, connector: source)
    create(:catalog, connector: destination)
    allow(Temporal).to receive(:start_workflow).and_return(true)
  end

  context "with valid params and active sync run" do
    it "cancels a schedule a manual sync" do
      create(:sync_run, sync:, workspace:, total_rows: 0, successful_rows: 0, failed_rows: 0,
                        source:, destination:, status: "querying")

      result = described_class.call(
        sync:
      )

      expect(Temporal).to have_received(:start_workflow).with(
        Workflows::TerminateWorkflow,
        "klaviyo-klaviyo-syncid-#{sync.id}",
        { options: { workflow_id: "terminate-klaviyo-klaviyo-syncid-#{sync.id}" } }
      )
      expect(result.success?).to eq(true)
    end
  end

  context "syncs with inactive sync_run" do
    it "fails to cancel a sync" do
      result = described_class.call(
        sync:
      )

      expect(result.failure?).to eq(true)
      expect(result.message).to eq("Sync cannot be cancelled due to no active sync run")
    end
  end
end
