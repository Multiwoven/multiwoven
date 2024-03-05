# frozen_string_literal: true

module Workflows
  class TerminateWorkflow < Temporal::Workflow
    include Activities
    def execute(workflow_id)
      TerminateWorkflowActivity.execute!(workflow_id)
    end
  end
end
