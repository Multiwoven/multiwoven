# frozen_string_literal: true

module Middlewares
  class UpdateSyncRunStatusMiddleware
    def call(metadata)
      yield
      sync_run = SyncRun.find_by(workflow_run_id: metadata.to_h["workflow_run_id"])
      Rails.logger.info({
        message: "UpdateSyncRunStatusMiddleware::call status before sync_run&.update_status_post_workflow",
        sync_run_id: sync_run.id,
        status: sync_run.status
      }.to_s)
      sync_run&.update_status_post_workflow
    end
  end
end
