# frozen_string_literal: true

module Enterprise
  module Agents
    module Workflows
      class RunWorkflow
        include Interactor

        delegate :workflow, :inputs, to: :context
        delegate :id, to: :workflow, prefix: true
        delegate :workspace, to: :workflow
        delegate :id, to: :workspace, prefix: true

        def call
          # Check if workflow is active
          context.fail!(message: "Workflow is not active", status: :failed_dependency) unless workflow.active?

          temporal_workflow_id = "workflow-#{workflow_id}-#{SecureRandom.uuid}"

          output = Temporal.start_workflow(
            Workflows::Agents::WorkflowOrchestrator,
            workflow_id,
            inputs,
            options: { workflow_id: temporal_workflow_id }
          )

          context.output = output
          context.workflow_run_id = temporal_workflow_id
        rescue StandardError => e
          Utils::ExceptionReporter.report(e, {
                                            workflow_id:,
                                            workspace_id:
                                          })
          Rails.logger.error "Failed to run workflow with Temporal. Error: #{e.message}"
          context.fail!(message: "Failed to run workflow", status: :internal_error)
        end
      end
    end
  end
end
