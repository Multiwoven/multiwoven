# frozen_string_literal: true

module Activities
  class CreateSyncRunActivity < Temporal::Activity
    def execute(sync_id)
      sync_run = SyncRun.find_or_initialize_by(status: "pending", sync_id:)
      sync_run.save! if sync_run.new_record?
      sync_run
    end
  end
end
