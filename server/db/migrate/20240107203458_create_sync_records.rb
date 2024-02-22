class CreateSyncRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :sync_records do |t|
      t.integer :sync_id
      t.integer :sync_run_id
      t.jsonb :record
      t.string :fingerprint

      t.timestamps
    end
  end
end
