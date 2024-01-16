class AddUniqueConstraintToSyncRecordFingerprint < ActiveRecord::Migration[7.1]
  def change
    add_index :sync_records, :fingerprint, unique: true
  end
end
