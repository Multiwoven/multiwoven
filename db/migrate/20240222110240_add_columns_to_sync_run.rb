class AddColumnsToSyncRun < ActiveRecord::Migration[7.1]
  def change
    add_column :sync_runs, :source_id, :integer
    add_column :sync_runs, :destination_id, :integer
    add_column :sync_runs, :model_id, :integer
  end
end
