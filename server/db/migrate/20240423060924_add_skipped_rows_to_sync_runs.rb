class AddSkippedRowsToSyncRuns < ActiveRecord::Migration[7.1]
  def up
    add_column :sync_runs, :skipped_rows, :integer, default: 0
  end

  def down
    remove_column :sync_runs, :skipped_rows
  end
end
