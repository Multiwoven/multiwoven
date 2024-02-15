# frozen_string_literal: true

module Activities
  class ExtractorActivity < Temporal::Activity
    timeouts(
      start_to_close: (ENV["TEMPORAL_ACTIVITY_START_TO_CLOSE"] || "3600").to_i
    )
    def execute(sync_run_id)
      sync_run = SyncRun.find(sync_run_id)

      sync_run.status = "in_progress"
      sync_run.started_at = Time.zone.now
      sync_run.save!

      # TODO: Select extraction strategy
      # based on sync mode eg: incremental/full_refresh
      extractor = ReverseEtl::Extractors::IncrementalDelta.new
      extractor.read(sync_run.id)
    end
  end
end
