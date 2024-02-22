class AddUniqueIndexToSyncRecords < ActiveRecord::Migration[7.1]
  def change
    add_index :sync_records, [:sync_run_id, :fingerprint], unique: true
  end
end
