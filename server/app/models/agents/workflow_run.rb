# frozen_string_literal: true

module Agents
  class WorkflowRun < ApplicationRecord
    include AASM

    validates :workflow_id, presence: true
    validates :workspace_id, presence: true
    validates :status, presence: true

    belongs_to :workflow, class_name: "Agents::Workflow"
    belongs_to :workspace

    after_initialize :set_defaults, if: :new_record?

    scope :active, -> { where(status: %i[pending in_progress]) }

    aasm column: :status, whiny_transitions: true do
      state :pending, initial: true
      state :in_progress
      state :completed
      state :failed
      state :cancelled

      event :start do
        transitions from: %i[pending in_progress], to: :in_progress
      end

      event :complete do
        transitions from: :in_progress, to: :completed
      end

      event :fail do
        transitions from: %i[pending in_progress], to: :failed
      end

      event :cancel do
        transitions from: %i[pending in_progress], to: :cancelled
      end
    end

    def set_defaults
      self.status ||= self.class.aasm.initial_state.to_s
    end

    def update_success
      complete!
    end

    def update_failure!
      fail!
    end

    def terminal_status?
      completed? || failed? || cancelled?
    end

    def duration_in_seconds
      now = Time.zone.now
      ((updated_at || now) - (created_at || now)).round
    end
  end
end
