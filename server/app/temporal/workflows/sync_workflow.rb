# frozen_string_literal: true

module Workflows
  class SyncWorkflow < Temporal::Workflow
    include Activities
    def execute(sync_id)
      sync = FetchSyncActivity.execute!(sync_id)
      return if sync.disabled?

      sync_run_id = CreateSyncRunActivity.execute!(sync.id)

      ExtractorActivity.execute!(sync_run_id)

      LoaderActivity.execute!(sync_run_id)

      ReporterActivity.execute!(sync_run_id)
    end
  end
end
