# frozen_string_literal: true

class Feedback < ApplicationRecord
  validates :data_app_id, presence: true
  validates :visual_component_id, presence: true
  validates :model_id, presence: true
  validates :feedback_type, presence: true

  belongs_to :data_app
  belongs_to :visual_component
  belongs_to :model

  enum feedback_type: { thumbs: 0, scale_input: 1, text_input: 2, dropdown: 3 }

  enum reaction: { positive: 0, negative: 1, scale_one: 2, scale_two: 3, scale_three: 4, scale_four: 5, scale_five: 6,
                   scale_six: 7, scale_seven: 8, scale_eight: 9, scale_nine: 10, scale_ten: 11 }
end
