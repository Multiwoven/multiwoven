# frozen_string_literal: true

require "rails_helper"

RSpec.describe Models::CreateModel do
  let(:workspace) { create(:workspace) }
  let(:connector) { create(:connector, workspace:) }
  let(:model) { create(:model, workspace:, connector:) }

  context "with valid params" do
    it "creates a model" do
      result = described_class.call(
        connector:,
        model_params: model.attributes.except("id", "created_at", "updated_at")
      )
      expect(result.success?).to eq(true)
      expect(result.model.persisted?).to eql(true)
      expect(result.model.connector_id).to eql(connector.id)
      expect(result.model.workspace_id).to eql(workspace.id)
    end
  end

  context "with invalid params" do
    let(:model_params) do
      { name: nil }
    end

    it "fails to create a model" do
      result = described_class.call(connector:, model_params:)
      expect(result.failure?).to eq(true)
    end
  end
end
