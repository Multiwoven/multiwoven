# frozen_string_literal: true

module Activities
  class ReporterActivity < Temporal::Activity
    def execute(sync_run_id)
      sync_run = SyncRun.find(sync_run_id)

      return unless sync_run.in_progress?

      total_rows, successful_rows, failed_rows = fetch_record_counts(sync_run)

      sync_run.update!(
        finished_at: Time.zone.now,
        total_rows:,
        successful_rows:,
        failed_rows:,
        status: determine_status(failed_rows, total_rows)
      )
    end

    private

    def fetch_record_counts(sync_run)
      total = sync_run.sync_records.count
      success = sync_run.sync_records.success.count
      failed = sync_run.sync_records.failed.count
      [total, success, failed]
    end

    def determine_status(failed_rows, total_rows)
      # TODO: Update status as incomplete if sync run retry exhausted
      # Sync failure should be marked based on threshold failure percentage
      failed_rows == total_rows ? :failed : :success
    end
  end
end
