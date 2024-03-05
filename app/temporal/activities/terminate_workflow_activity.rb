# frozen_string_literal: true

module Activities
  class TerminateWorkflowActivity < Temporal::Activity
    def execute(workflow_id)
      Temporal.terminate_workflow(workflow_id)
    end
  end
end
