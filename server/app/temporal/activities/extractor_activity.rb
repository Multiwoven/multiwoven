# frozen_string_literal: true

module Activities
  class ExtractorActivity < Temporal::Activity
    class SourceReadFailed < Temporal::ActivityException; end
    timeouts(
      start_to_close: (ENV["TEMPORAL_ACTIVITY_START_TO_CLOSE_IN_SEC"] || "172800").to_i,
      heartbeat: (ENV["TEMPORAL_ACTIVITY_HEARTBEAT_TIMEOUT_IN_SEC"] || "1200").to_i
    )

    retry_policy(
      interval: (ENV["TEMPORAL_ACTIVITY_RETRY_INTERVAL_IN_SEC"] || "1").to_i,
      backoff: (ENV["TEMPORAL_ACTIVITY_RETRY_BACK_OFF"] || "1").to_i,
<<<<<<< HEAD
      max_attempts: (ENV["TEMPORAL_ACTIVITY_RETRY_MAX_ATTEMPT"] || "3").to_i
      # non_retriable_errors: [SyncRunStateExeption]
=======
      max_attempts: "10".to_i
>>>>>>> b61bc2d9c (fix(CE): fail sync run on source connection error instead of retrying (BE-2063) (#2369))
    )

    def execute(sync_run_id)
      sync_run = SyncRun.find(sync_run_id)

      return log_error(sync_run) unless sync_run.may_start?

      # state of sync run to started only if current state in [ pending,started,querying]
      sync_run.start
      sync_run.update(started_at: Time.zone.now, error: nil)

      extractor = select_extractor(sync_run)
      extractor.read(sync_run.id, activity)
    rescue SourceReadFailed => e
      record_source_read_failure(sync_run, e)
      raise
    end

    private

    # Retriable: UpdateSyncRunStatusMiddleware fails the run once retries are exhausted.
    def record_source_read_failure(sync_run, error)
      sync_run.update!(error: error.message)
      Rails.logger.error({
        error_message: error.message,
        sync_run_id: sync_run.id,
        sync_id: sync_run.sync_id,
        stack_trace: nil
      }.to_s)
    end

    def select_extractor(sync_run)
      return test_sync_extractor if sync_run.test?

      if sync_run.sync.source.connector_name == "Firecrawl"
        ReverseEtl::Extractors::WebScraping.new
      else
        sync_mode_extractor(sync_run.sync.sync_mode.to_sym)
      end
    end

    def test_sync_extractor
      ReverseEtl::Extractors::TestSyncExtractor.new
    end

    def sync_mode_extractor(sync_mode)
      case sync_mode
      when :incremental
        ReverseEtl::Extractors::IncrementalDelta.new
      when :full_refresh
        ReverseEtl::Extractors::FullRefresh.new
      else
        raise "Unsupported sync mode: #{sync_mode}"
      end
    end

    def log_error(sync_run)
      Rails.logger.error({
        error_message: "SyncRun cannot start from its current state: #{sync_run.status}",
        sync_run_id: sync_run.id,
        stack_trace: nil
      }.to_s)
    end
  end
end
