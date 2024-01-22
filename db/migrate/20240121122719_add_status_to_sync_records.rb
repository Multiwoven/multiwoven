class AddStatusToSyncRecords < ActiveRecord::Migration[7.1]
  def change
    add_column :sync_records, :status, :integer, default: 0
  end
end
