class SetValuesForExistingSyncRuns < ActiveRecord::Migration[7.1]
  def change
    SyncRun.find_each do |sync_run|
      sync_attributes = {
        workspace_id: sync_run.sync.workspace_id,
        source_id: sync_run.sync.source_id,
        destination_id: sync_run.sync.destination_id,
        model_id: sync_run.sync.model_id
      }
      sync_run.update(sync_attributes)
    end
  end
end
