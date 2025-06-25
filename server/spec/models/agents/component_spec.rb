# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::Component, type: :model do
  describe "associations" do
    it { should belong_to(:workflow) }
    it { should belong_to(:workspace) }
  end

  describe "enums" do
    it {
      should define_enum_for(:component_type).with_values(
        chat_input: 0,
        chat_output: 1,
        data_storage: 2,
        llm_model: 3,
        prompt_template: 4,
        vector_store: 5
      )
    }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:component_type) }
    it { should validate_presence_of(:configuration) }
  end

  describe "position storage" do
    let(:component) { create(:component) }

    it "stores position as JSON" do
      position_data = { "x" => 100, "y" => 200 }
      component.position = position_data
      component.save
      component.reload
      expect(component.position).to eq(position_data)
    end
  end
end
