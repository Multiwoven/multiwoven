# frozen_string_literal: true

require "rails_helper"

RSpec.describe Models::UpdateModel do
  let(:workspace) { create(:workspace) }
  let(:connector) { create(:connector, workspace:) }
  let(:model) { create(:model, workspace:, connector:) }

  context "with valid params" do
    it "updates a model" do
      new_name = Faker::Name.name
      result = described_class.call(
        model:,
        model_params: {
          name: new_name
        }
      )
      expect(result.success?).to eq(true)
      expect(result.model.name).to eql(new_name)
    end
  end

  context "with invalid params" do
    let(:model_params) do
      {
        name: nil
      }
    end

    it "fails to update a model" do
      result = described_class.call(model:, model_params:)
      expect(result.failure?).to eq(true)
    end
  end
end
