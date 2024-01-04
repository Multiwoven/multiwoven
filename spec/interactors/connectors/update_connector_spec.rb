# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connectors::UpdateConnector do
  let(:connector) { create(:connector) }

  context "with valid params" do
    it "updates a connector" do
      new_name = Faker::Name.name
      result = described_class.call(
        connector:,
        connector_params: {
          name: new_name
        }
      )
      expect(result.success?).to eq(true)
      expect(result.connector.name).to eql(new_name)
    end
  end

  context "with invalid params" do
    let(:connector_params) do
      {
        workspace_id: nil
      }
    end

    it "fails to update a connector" do
      result = described_class.call(connector:, connector_params:)
      expect(result.failure?).to eq(true)
    end
  end
end
