class AddErrorJsonToSyncRecords < ActiveRecord::Migration[7.1]
  def change
    add_column :sync_records, :error, :jsonb
  end
end
