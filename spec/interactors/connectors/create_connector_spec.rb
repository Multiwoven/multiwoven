# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connectors::CreateConnector do
  let(:workspace) { create(:workspace) }

  context "with valid params" do
    let(:connector) { create(:connector, workspace:) }

    it "creates a connector" do
      result = described_class.call(
        workspace:,
        connector_params: connector.attributes.except("id")
      )
      expect(result.success?).to eq(true)
      expect(result.connector.persisted?).to eql(true)
      expect(result.connector.workspace_id).to eql(workspace.id)
    end
  end

  context "with invalid params" do
    let(:connector_params) do
      { workspace_id: nil,
        connector_definition_id: nil,
        connector_type: nil,
        configuration: nil,
        name: nil }
    end

    it "fails to create a connector" do
      result = described_class.call(workspace:, connector_params:)
      expect(result.failure?).to eq(true)
    end
  end
end
