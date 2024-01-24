# frozen_string_literal: true

module Activities
  class ScheduleSyncActivity < Temporal::Activity
    def execute(sync_id)
      sync = Sync.find_by(id: sync_id)

      # TODO: Catch exception if workflow is not running
      Temporal.terminate_workflow(sync.workflow_id) if sync.workflow_id.present?

      workflow_id = SecureRandom.uuid

      Temporal.schedule_workflow(
        Workflows::SyncWorkflow, sync.schedule_cron_expression,
        sync.id,
        options: {
          workflow_id:
        }
      )

      sync.update!(workflow_id:)
    end
  end
end
