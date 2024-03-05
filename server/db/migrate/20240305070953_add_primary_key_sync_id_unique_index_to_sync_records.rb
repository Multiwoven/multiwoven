class AddPrimaryKeySyncIdUniqueIndexToSyncRecords < ActiveRecord::Migration[7.1]
  def up
    add_index :sync_records, [:sync_id, :primary_key], unique: true, name: 'index_sync_records_on_sync_id_and_primary_key'
  end

  def down
    remove_index :sync_records, name: 'index_sync_records_on_sync_id_and_primary_key'
  end
end
