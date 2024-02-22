class RemoveUniqueConstraintFromSyncRecordFingerprint < ActiveRecord::Migration[7.1]
  def change
    remove_index :sync_records, :fingerprint
  end
end
