# frozen_string_literal: true

module Agents
  class WorkflowRun < ApplicationRecord
    include AASM

    validates :workflow_id, presence: true
    validates :workspace_id, presence: true
    validates :status, presence: true

    belongs_to :workflow, class_name: "Agents::Workflow"
    belongs_to :workspace

    has_one :workflow_log, class_name: "Agents::WorkflowLog", dependent: :destroy
<<<<<<< HEAD
=======
    has_many :llm_routing_logs, dependent: :destroy
    has_many :llm_usage_logs, dependent: :destroy
>>>>>>> 6f1a6fb16 (chore(CE): Add LLM Usage Log (#1649))

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

    def log_component(options)
      workflow_log = self.workflow_log
      return if options.blank? && workflow_log.nil?

      workflow_log.logs ||= {}
      workflow_log.logs["components"] ||= []
      workflow_log.logs["components"] << options

      workflow_log.save!
    end

    def finalize(output = nil)
      update!(finished_at: Time.zone.now)
      workflow_log = self.workflow_log
      return unless workflow_log

      workflow_log.update!(output: output.to_json)
      workflow_log.save!
    end

    def duration_in_seconds
      now = Time.zone.now
      ((updated_at || now) - (created_at || now)).round
    end

    def tokens_used
      llm_usage_logs.sum(:estimated_input_tokens) + llm_usage_logs.sum(:estimated_output_tokens)
    end
  end
end
