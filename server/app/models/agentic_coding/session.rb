# frozen_string_literal: true

module AgenticCoding
  class Session < ApplicationRecord
    belongs_to :workspace
    belongs_to :user
    belongs_to :agentic_coding_app, class_name: "AgenticCoding::App", inverse_of: :sessions

    has_many :prompts, class_name: "AgenticCoding::Prompt", dependent: :destroy, inverse_of: :agentic_coding_session
    has_many :deployments, class_name: "AgenticCoding::Deployment", dependent: :destroy,
                           inverse_of: :agentic_coding_session

    enum status: {
      active: 0,
      paused: 1,
      ended: 2
    }

    validates :status, presence: true
  end
end
