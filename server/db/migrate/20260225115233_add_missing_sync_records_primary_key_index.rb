class AddMissingSyncRecordsPrimaryKeyIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    return if index_exists?(:sync_records, [:sync_id, :primary_key], name: "index_sync_records_on_sync_id_and_primary_key")

    duplicate_count = safety_assured do
      execute(<<~SQL).first["count"].to_i
        SELECT COUNT(*) AS count FROM (
          SELECT sync_id, primary_key
          FROM sync_records
          GROUP BY sync_id, primary_key
          HAVING COUNT(*) > 1
        ) AS duplicates
      SQL
    end

    if duplicate_count > 0
      raise "Cannot create unique index: #{duplicate_count} duplicate (sync_id, primary_key) groups found. " \
            "Clean up duplicates before running this migration."
    end

    add_index :sync_records, [:sync_id, :primary_key],
              unique: true,
              name: "index_sync_records_on_sync_id_and_primary_key",
              algorithm: :concurrently
  end

  def down
    if index_exists?(:sync_records, [:sync_id, :primary_key], name: "index_sync_records_on_sync_id_and_primary_key")
      remove_index :sync_records, name: "index_sync_records_on_sync_id_and_primary_key"
    end
  end
end
