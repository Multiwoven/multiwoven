# frozen_string_literal: true

module Agents
  class WorkflowApproval < ApplicationRecord
    belongs_to :workflow_run, class_name: "Agents::WorkflowRun"
    belongs_to :workspace
    belongs_to :resolved_by, class_name: "User", optional: true

    validates :workflow_run_id, :workspace_id, :status, :message,
              :temporal_workflow_id, :temporal_run_id, presence: true

    enum :status, { pending: 0, approved: 1, rejected: 2, timed_out: 3 }

    scope :active, -> { where(status: :pending) }
  end
end
