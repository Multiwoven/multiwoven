# frozen_string_literal: true

module Agents
  class Workflow < ApplicationRecord
    belongs_to :workspace

    enum status: { draft: 0, published: 1 }
    enum trigger_type: { interactive: 0, scheduled: 1, api_trigger: 2 }

    validates :name, presence: true
    validates :token, uniqueness: true, allow_nil: true

    store :configuration, coder: JSON

    before_save :generate_token_on_publish

    private

    def generate_token_on_publish
      self.token = SecureRandom.hex(16) if status_changed? && published?
    end
  end
end
