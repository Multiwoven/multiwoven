class AddSyncIntervalAndUnitToSyncs < ActiveRecord::Migration[7.1]
  def change
    add_column :syncs, :sync_interval, :integer
    add_column :syncs, :sync_interval_unit, :integer
  end
end