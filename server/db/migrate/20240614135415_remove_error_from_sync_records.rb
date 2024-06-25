class RemoveErrorFromSyncRecords < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :sync_records, :error, :text }
  end
end
