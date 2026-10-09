# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::Component, type: :model do
  describe "associations" do
    it { should belong_to(:workflow) }
    it { should belong_to(:workspace) }
    it { should have_many(:source_edges).class_name("Agents::Edge").dependent(:destroy) }
    it { should have_many(:target_edges).class_name("Agents::Edge").dependent(:destroy) }
<<<<<<< HEAD
=======
    it { should have_many(:llm_routing_logs).dependent(:destroy) }
    it { should have_many(:llm_usage_logs).dependent(:destroy) }
>>>>>>> 6f1a6fb16 (chore(CE): Add LLM Usage Log (#1649))
  end

  describe "enums" do
    it {
      should define_enum_for(:component_type).with_values(
        chat_input: 0,
        chat_output: 1,
        data_storage: 2,
        llm_model: 3,
        prompt_template: 4,
        vector_store: 5,
        python_custom: 6
      )
    }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:component_type) }
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
