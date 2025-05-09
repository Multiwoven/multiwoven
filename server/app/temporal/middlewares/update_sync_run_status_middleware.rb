# frozen_string_literal: true

module Middlewares
  class UpdateSyncRunStatusMiddleware
    def call(metadata)
      yield
      sync_run = SyncRun.find_by(workflow_run_id: metadata.to_h["workflow_run_id"])
      sync_run&.update_status_post_workflow
    end
  end
end
