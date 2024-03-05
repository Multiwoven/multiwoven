class ChangeStartedAtAndFinishedAtInSyncRuns < ActiveRecord::Migration[7.1]
  def change
    change_column_null :sync_runs, :started_at, true
    change_column_null :sync_runs, :finished_at, true
  end
end
