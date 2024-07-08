class RenameErrorToLogsInSyncRecords < ActiveRecord::Migration[7.1]
  def up
    safety_assured { rename_column :sync_records, :error, :logs }
  end

  def down
    safety_assured { rename_column :sync_records, :logs , :error }
  end
end
