# frozen_string_literal: true

module Activities
  class ReporterActivity < Temporal::Activity
    def execute(sync_run_id)
      sync_run = SyncRun.find(sync_run_id)

      return log_error(sync_run) unless sync_run.may_complete?

      total_rows, successful_rows, failed_rows = fetch_record_counts(sync_run)

      sync_run.update!(
        finished_at: Time.zone.now,
        total_rows:,
        successful_rows:,
        failed_rows:
      )
      sync_run.update_success
    end

    private

    def fetch_record_counts(sync_run)
      total = sync_run.sync_records.count
      success = sync_run.sync_records.success.count
      failed = sync_run.sync_records.failed.count
      [total, success, failed]
    end

    def log_error(sync_run)
      Temporal.logger.error(
        error_message: "SyncRun cannot complete from its current state: #{sync_run.status}",
        sync_run_id: sync_run.id,
        stack_trace: nil
      )
    end
  end
end
