# frozen_string_literal: true

module Activities
  class ReporterActivity < Temporal::Activity
    retry_policy(
      interval: 1,
      backoff: 1,
      max_attempts: 3
    )
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
      Rails.logger.info({
        message: "ReporterActivity::execute status before sync_run.update_success",
        sync_run_id: sync_run.id,
        status: sync_run.status
      }.to_s)
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
      Rails.logger.error({
        error_message: "SyncRun cannot complete from its current state: #{sync_run.status}",
        sync_run_id: sync_run.id,
        stack_trace: nil
      }.to_s)
    end
  end
end
