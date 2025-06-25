# frozen_string_literal: true

module Agents
  class Workflow < ApplicationRecord
    belongs_to :workspace
    has_many :edges, dependent: :destroy
    has_many :components, dependent: :destroy

    enum status: { draft: 0, published: 1 }
    enum trigger_type: { website_chatbot: 0, chat_assistant: 1, scheduled: 2, api_trigger: 3 }

    validates :name, presence: true, uniqueness: { scope: :workspace_id, case_sensitive: false }
    validates :token, uniqueness: true, allow_nil: true

    store :configuration, coder: JSON

    before_save :generate_token_on_publish

    private

    def generate_token_on_publish
      self.token = SecureRandom.hex(16) if status_changed? && published?
    end
  end
end
