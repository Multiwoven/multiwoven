# frozen_string_literal: true

require "rails_helper"

RSpec.describe Workflows::ScheduleSyncWorkflow do
  let(:source) do
    create(:connector, connector_type: "source", connector_name: "Snowflake")
  end
  let(:destination) { create(:connector, connector_type: "destination") }
  let!(:catalog) { create(:catalog, connector: destination) }
  let(:sync) { create(:sync, source:, destination:) }
  let(:sync_run) { create(:sync_run, sync:) }
  subject { described_class }

  before { allow(Activities::ScheduleSyncActivity).to receive(:execute!) }

  it "executes schedule sync workflow" do
    # TODO: Add more tests
    subject.execute_locally(sync.id)

    expect(Activities::ScheduleSyncActivity).to have_received(:execute!).twice.with(sync.id)
  end
end
