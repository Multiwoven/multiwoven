# frozen_string_literal: true

class ChatMessage < ApplicationRecord
  validates :visual_component_id, presence: true
  validates :content, presence: true

  counter_culture %i[visual_component data_app]

  belongs_to :workspace
  belongs_to :data_app_session
  belongs_to :visual_component

  enum role: { user: 0, assistant: 1 }
end
