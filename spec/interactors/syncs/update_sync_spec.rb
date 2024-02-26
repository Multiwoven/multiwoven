# frozen_string_literal: true

require "rails_helper"

RSpec.describe Syncs::UpdateSync do
  let(:workspace) { create(:workspace) }
  let(:source) { create(:connector, workspace:) }
  let(:destination) { create(:connector, workspace:) }
  let(:model) { create(:model, workspace:, connector: source) }
  let(:sync) { create(:sync, status: 0, workspace:, source:, destination:, model:) }

  before do
    create(:catalog, connector: source)
    create(:catalog, connector: destination)
  end

  context "with valid params" do
    it "updates sync" do
      expect(sync.status).to eql("healthy")
      result = described_class.call(
        sync:,
        sync_params: { status: 1 }
      )
      expect(result.success?).to eq(true)
      expect(result.sync.persisted?).to eql(true)
      expect(result.sync.status).to eql("failed")
    end
  end

  context "with invalid params" do
    let(:sync_params) do
      { source_id: nil }
    end

    it "fails to update sync" do
      result = described_class.call(sync:, sync_params:)
      expect(result.failure?).to eq(true)
    end
  end
end
