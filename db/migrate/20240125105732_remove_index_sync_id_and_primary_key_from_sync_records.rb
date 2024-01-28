class RemoveIndexSyncIdAndPrimaryKeyFromSyncRecords < ActiveRecord::Migration[7.1]
  def change
    remove_index :sync_records, name: 'index_sync_records_on_sync_id_and_primary_key'
  end
end
