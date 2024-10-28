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
    it { should validate_presence_of(:feedback_type) }
  end

  describe "enum" do
    it { should define_enum_for(:feedback_type).with_values(thumbs: 0, scale_input: 1, text_input: 2, dropdown: 3) }

    it do
      should define_enum_for(:reaction).with_values(
        negative: -99,
        positive: 99,
        scale_one: 1,
        scale_two: 2,
        scale_three: 3,
        scale_four: 4,
        scale_five: 5,
        scale_six: 6,
        scale_seven: 7,
        scale_eight: 8,
        scale_nine: 9,
        scale_ten: 10
      )
    end
  end
end
