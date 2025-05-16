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
      
      # Add more detailed logging
      Rails.logger.info("Scheduling sync #{sync_id} with cron expression: #{sync.schedule_cron_expression}")
      
      # Terminate existing workflows more aggressively
      if sync.workflow_id.present?
        begin

          Rails.logger.info("Attempting to terminate existing workflow: #{sync.workflow_id}")
          Temporal.terminate_workflow(sync.workflow_id)
        rescue StandardError => e
          Utils::ExceptionReporter.report(e, { sync_id: })
          Rails.logger.error("Failed to terminate workflow error: #{e.message}")
        end
      end
      
      # Use a more unique workflow ID
      source_connector_name = sync.source.connector_name.downcase
      destination_connector_name = sync.destination.connector_name.downcase
      timestamp = Time.now.to_i
      workflow_id = "#{source_connector_name}-#{destination_connector_name}-syncid-#{sync_id}-#{timestamp}"
      
      # Check if there are any active sync runs before scheduling
      if sync.sync_runs.active.exists?
        Rails.logger.warn("Skipping schedule for sync #{sync_id} because there are active sync runs")
        return
      end
      
      # Schedule the sync with the user-configured schedule
      Rails.logger.info("Scheduling workflow with ID: #{workflow_id}")
      Temporal.schedule_workflow(
        Workflows::SyncWorkflow, sync.schedule_cron_expression,
        sync.id,
        options: {
          workflow_id:
        }
      )
      
      # Only execute immediately if this is the first run and there are no active runs
      if !sync.sync_runs.any?
        Rails.logger.info("Executing first sync run immediately for sync_id: #{sync.id}")
        immediate_workflow_id = "immediate-#{workflow_id}"
        Rails.logger.info("Starting immediate workflow with ID: #{immediate_workflow_id}")
        Temporal.start_workflow(
          Workflows::SyncWorkflow,
          sync.id,
          options: { workflow_id: immediate_workflow_id }
        )
      end
      
      sync.update!(workflow_id:)
    end
  end
end
