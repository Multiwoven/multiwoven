class AddTotalQueryRowsToSyncRuns < ActiveRecord::Migration[7.1]
  def change
    add_column :sync_runs, :total_query_rows, :integer
  end
end
