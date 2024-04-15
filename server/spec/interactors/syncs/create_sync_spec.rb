# frozen_string_literal: true

require "rails_helper"

RSpec.describe Syncs::CreateSync do
  let(:workspace) { create(:workspace) }
  let(:source) { create(:connector, workspace:, connector_type: "source") }
  let(:destination) { create(:connector, workspace:) }
  let(:model) { create(:model, workspace:, connector: source) }
  let(:sync) { build(:sync, workspace:, source:, destination:, model:) }

  before do
    create(:catalog, connector: source)
    create(:catalog, connector: destination)
  end

  context "with valid params" do
    it "creates a sync" do
      result = described_class.call(
        workspace:,
        sync_params: sync.attributes.except("id", "created_at", "updated_at").with_indifferent_access
      )
      expect(result.success?).to eq(true)
      expect(result.sync.persisted?).to eql(true)
      expect(result.sync.source_id).to eql(source.id)
      expect(result.sync.destination_id).to eql(destination.id)
      expect(result.sync.model_id).to eql(model.id)
    end
  end

  context "with invalid params" do
    let(:sync_params) do
      sync.attributes.except("id", "created_at", "destination_id")
    end

    it "fails to create sync" do
      result = described_class.call(workspace:, sync_params: sync_params.with_indifferent_access)
      expect(result.failure?).to eq(true)
    end
  end
end
