# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feedback, type: :model do
  describe "associations" do
    it { should belong_to(:data_app) }
    it { should belong_to(:visual_component) }
    it { should belong_to(:model) }
  end

  describe "validations" do
    it { should validate_presence_of(:data_app_id) }
    it { should validate_presence_of(:visual_component_id) }
    it { should validate_presence_of(:model_id) }
    it { should validate_presence_of(:reaction) }
  end

  describe "enum" do
    it { should define_enum_for(:reaction).with_values(positive: 0, negative: 1) }
  end
end
