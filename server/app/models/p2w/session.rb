# frozen_string_literal: true

module P2w
  class Session < ApplicationRecord
    self.table_name = "prompt_to_workflow_sessions"

    TERMINAL_STATUSES = %w[completed failed max_turns expired].freeze

    belongs_to :workflow, class_name: "Agents::Workflow"
    belongs_to :workspace
    has_many :events, class_name: "P2w::SessionEvent",
                      foreign_key: :prompt_to_workflow_session_id,
                      inverse_of: :session,
                      dependent: :destroy

    validates :session_id, presence: true, uniqueness: true
    validates :workflow_id, :workspace_id, :status, :expires_at, presence: true
    validates :status, inclusion: { in: %w[running clarification_pending completed failed max_turns expired] }

    scope :active, -> { where(status: %w[running clarification_pending]) }
    scope :not_expired, -> { where("expires_at > ?", Time.current) }

    def terminal?
      status.in?(TERMINAL_STATUSES)
    end

    def replayable?
      expires_at > Time.current
    end

    def accepts_clarification?
      status == "clarification_pending" && !expired?
    end

    def expired?
      expires_at <= Time.current
    end
  end
end
