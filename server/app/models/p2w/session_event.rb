# frozen_string_literal: true

module P2w
  class SessionEvent < ApplicationRecord
    self.table_name = "prompt_to_workflow_session_events"

    belongs_to :session, class_name: "P2w::Session",
                         foreign_key: :prompt_to_workflow_session_id,
                         inverse_of: :events

    validates :sequence, presence: true,
                         uniqueness: { scope: :prompt_to_workflow_session_id },
                         numericality: { greater_than_or_equal_to: 0 }
    validates :event_type, presence: true
  end
end
