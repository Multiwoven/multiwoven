# frozen_string_literal: true

module Activities
  class TerminateWorkflowActivity < Temporal::Activity
    timeouts(
      start_to_close: 60
    )
    retry_policy(
      interval: 1,
      backoff: 1,
      max_attempts: 3,
      non_retriable_errors: [GRPC::NotFound]
    )
    def execute(workflow_id)
      Temporal.terminate_workflow(workflow_id)
    end
  end
end
