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
        positive: 0,
        negative: 1,
        scale_one: 2,
        scale_two: 3,
        scale_three: 4,
        scale_four: 5,
        scale_five: 6,
        scale_six: 7,
        scale_seven: 8,
        scale_eight: 9,
        scale_nine: 10,
        scale_ten: 11
      )
    end
  end
end
