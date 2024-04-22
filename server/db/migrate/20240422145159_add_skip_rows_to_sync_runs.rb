class AddSkipRowsToSyncRuns < ActiveRecord::Migration[7.1]
  def up
    add_column :sync_runs, :skip_rows, :integer, default: 0
  end

  def down
    remove_column :sync_runs, :skip_rows
  end
end
