class RemoveIndexAndAddNewIndexToSyncRecords < ActiveRecord::Migration[7.1]
  def change
    remove_index :sync_records, name: "index_sync_records_on_sync_run_id_and_fingerprint"
    add_index :sync_records, [:sync_id, :fingerprint], unique: true, name: "index_sync_records_on_sync_id_and_fingerprint"
  end
end
