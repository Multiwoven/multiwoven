# frozen_string_literal: true

require "rails_helper"

RSpec.describe Workflows::SyncWorkflow do
  let(:source) do
    create(:connector, connector_type: "source", connector_name: "Snowflake")
  end
  let(:destination) { create(:connector, connector_type: "destination") }
  let!(:catalog) { create(:catalog, connector: destination) }
  let(:sync) { create(:sync, source:, destination:) }
  let(:sync_run) { create(:sync_run, sync:) }
  subject { described_class }

  before { allow(Activities::ExtractorActivity).to receive(:execute!) }
  before { allow(Activities::LoaderActivity).to receive(:execute!) }
  before { allow(Activities::ReporterActivity).to receive(:execute!) }

  it "executes sync workflow" do
    # TODO: Add more tests
    subject.execute_locally(sync.id)

    expect(Activities::ExtractorActivity).to have_received(:execute!).with(sync.sync_runs.first.id)
    expect(Activities::LoaderActivity).to have_received(:execute!).with(sync.sync_runs.first.id)
    expect(Activities::ReporterActivity).to have_received(:execute!).with(sync.sync_runs.first.id)
    expect(sync.sync_runs.first.sync_run_type).to eq("general")
  end

  it "executes sync workflow with sync run type test" do
    # TODO: Add more tests
    subject.execute_locally(sync.id, "test")

    expect(Activities::ExtractorActivity).to have_received(:execute!).with(sync.sync_runs.first.id)
    expect(Activities::LoaderActivity).to have_received(:execute!).with(sync.sync_runs.first.id)
    expect(Activities::ReporterActivity).to have_received(:execute!).with(sync.sync_runs.first.id)
    expect(sync.sync_runs.first.sync_run_type).to eq("test")
  end
end
