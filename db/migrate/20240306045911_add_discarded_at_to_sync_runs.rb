class AddDiscardedAtToSyncRuns < ActiveRecord::Migration[7.1]
  def change
    add_column :sync_runs, :discarded_at, :datetime
    add_index :sync_runs, :discarded_at
  end
end
