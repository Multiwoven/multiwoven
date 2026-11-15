# frozen_string_literal: true

module AgenticCoding
  class Prompt < ApplicationRecord
    belongs_to :agentic_coding_app, class_name: "AgenticCoding::App", inverse_of: :prompts
    belongs_to :agentic_coding_session, class_name: "AgenticCoding::Session", inverse_of: :prompts

    enum role: { user: 0, assistant: 1 }
    enum status: {
      queued: 0,
      running: 1,
      completed: 2,
      failed: 3
    }

    validates :content, :role, :status, presence: true
  end
end
