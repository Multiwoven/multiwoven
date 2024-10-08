# frozen_string_literal: true

class Feedback < ApplicationRecord
  validates :data_app_id, presence: true
  validates :visual_component_id, presence: true
  validates :model_id, presence: true
  validates :reaction, presence: true

  belongs_to :data_app
  belongs_to :visual_component
  belongs_to :model

  enum reaction: { positive: 0, negative: 1 }
end
