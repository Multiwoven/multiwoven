class AddPrimaryKeyToSyncRecords < ActiveRecord::Migration[7.1]
  def change
    add_column :sync_records, :primary_key, :string
    add_index :sync_records, [:sync_id, :primary_key], unique: true
  end
end
