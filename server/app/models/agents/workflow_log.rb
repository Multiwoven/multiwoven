# frozen_string_literal: true

module Agents
  class WorkflowLog < ApplicationRecord
    belongs_to :workflow
    belongs_to :workflow_run
    belongs_to :workspace

    validates :workflow_id, :workflow_run, :input, :workspace_id, presence: true
  end
end
