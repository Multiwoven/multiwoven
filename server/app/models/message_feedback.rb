# frozen_string_literal: true

class MessageFeedback < ApplicationRecord
  acts_as_taggable_on :tags

  validates :data_app_id, presence: true
  validates :visual_component_id, presence: true
  validates :model_id, presence: true
  validates :feedback_type, presence: true
  validates :chatbot_interaction, presence: true

  counter_culture %i[visual_component data_app]

  belongs_to :data_app
  belongs_to :visual_component
  belongs_to :model
  belongs_to :workspace

  enum feedback_type: { thumbs: 0, scale_input: 1, text_input: 2, dropdown: 3, multiple_choice: 4 }

  enum reaction: { negative: -99, positive: 99, scale_one: 1, scale_two: 2, scale_three: 3, scale_four: 4,
                   scale_five: 5, scale_six: 6, scale_seven: 7, scale_eight: 8, scale_nine: 9, scale_ten: 10 }
end
