# frozen_string_literal: true

module Activities
  class CreateSyncRunActivity < Temporal::Activity
    def execute(sync_id)
      sync = Sync.find(sync_id)
      sync_run = SyncRun.find_or_initialize_by(sync_id:, status: :pending) do |run|
        run.workspace_id = sync.workspace_id
        run.source_id = sync.source_id
        run.destination_id = sync.destination_id
        run.model_id = sync.model_id
      end
      sync_run.save! if sync_run.new_record?
      sync_run.id
    end
  end
end
