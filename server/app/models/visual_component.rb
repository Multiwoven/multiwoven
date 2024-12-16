# frozen_string_literal: true

class VisualComponent < ApplicationRecord
  validates :workspace_id, presence: true
  validates :component_type, presence: true
  validates :model_id, presence: true
  validates :data_app_id, presence: true

  enum component_type: { doughnut: 0, bar: 1, data_table: 2, visual_text: 3, custom: 4, chat_bot: 5 }

  belongs_to :workspace
  belongs_to :data_app
  belongs_to :model

  has_many :feedbacks, dependent: :destroy
end
