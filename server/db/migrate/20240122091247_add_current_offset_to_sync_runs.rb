class AddCurrentOffsetToSyncRuns < ActiveRecord::Migration[7.1]
  def change
    add_column :sync_runs, :current_offset, :integer, default: 0
  end
end
