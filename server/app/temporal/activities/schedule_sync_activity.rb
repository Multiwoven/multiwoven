# frozen_string_literal: true

module Activities
  class ScheduleSyncActivity < Temporal::Activity
    retry_policy(
      interval: 1,
      backoff: 1,
      max_attempts: 3
    )

    def execute(sync_id)
      sync = Sync.find_by(id: sync_id)

      begin
        Temporal.terminate_workflow(sync.workflow_id) if sync.workflow_id.present?
      rescue StandardError => e
        Utils::ExceptionReporter.report(e, {
                                          sync_id:
                                        })
        Rails.logger.error("Failed to terminate workflow error: #{e.message}")
      end

      source_connector_name = sync.source.connector_name.downcase
      destination_connector_name = sync.destination.connector_name.downcase

      workflow_id = "#{source_connector_name}-#{destination_connector_name}-syncid-#{sync_id}"

      # Schedule the sync with the user-configured schedule for future runs
      Temporal.schedule_workflow(
        Workflows::SyncWorkflow, sync.schedule_cron_expression,
        sync.id,
        options: {
          workflow_id:
        }
      )

      # If this is the first run, execute the sync immediately
      if !sync.sync_runs.any?
        Rails.logger.info("Executing first sync run immediately for sync_id: #{sync.id}")
        # Start the workflow immediately for the first run
        Temporal.start_workflow(
          Workflows::SyncWorkflow,
          sync.id,
          options: { workflow_id: "immediate-#{workflow_id}" }
        )
      end

      sync.update!(workflow_id:)
    end
  end
end
