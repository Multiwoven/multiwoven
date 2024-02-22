class AddSyncModeToSyncs < ActiveRecord::Migration[7.1]
  def change
    add_column :syncs, :sync_mode, :integer
  end
end
