# frozen_string_literal: true

class ChatMessage < ApplicationRecord
  belongs_to :workspace
  belongs_to :data_app_session
  belongs_to :visual_component

  enum role: { user: 0, assistant: 1 }

  validates :content, presence: true
end
