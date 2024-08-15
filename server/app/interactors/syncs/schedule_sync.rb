# frozen_string_literal: true

module Syncs
  class ScheduleSync
    include Interactor

    def call
      sync = context.sync

      if sync.sync_runs.active.exists?
        context.fail!(message: "Sync cannot be scheduled due to active sync run", status: :failed_dependency)
      end

      source_connector_name = sync.source.connector_name.downcase
      destination_connector_name = sync.destination.connector_name.downcase
      workflow_id = "#{source_connector_name}-#{destination_connector_name}-syncid-#{sync.id}"

      sync.update!(workflow_id:)
      Temporal.start_workflow(
        Workflows::SyncWorkflow,
        sync.id,
        options: { workflow_id: }
      )
    rescue StandardError => e
      Utils::ExceptionReporter.report(e, {
                                        sync_id: sync.id
                                      })
      Rails.logger.error "Failed to schedule sync with Temporal. Error: #{e.message}"
    end
  end
end
