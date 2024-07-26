# frozen_string_literal: true

module Syncs
  class CancelSync
    include Interactor

    def call
      sync = context.sync

      unless sync.sync_runs.active.exists?
        context.fail!(message: "Sync cannot be cancelled due to no active sync run", status: :failed_dependency)
      end

      terminate_workflow_id = "terminate-#{sync.workflow_id}"

      Temporal.start_workflow(
        Workflows::TerminateWorkflow,
        sync.workflow_id,
        options: { workflow_id: terminate_workflow_id }
      )

      sync.sync_runs.active.last.cancel!
    rescue StandardError => e
      Utils::ExceptionReporter.report(e, {
                                        sync_id: sync.id
                                      })
      Rails.logger.error "Failed to schedule sync with Temporal. Error: #{e.message}"
    end
  end
end
