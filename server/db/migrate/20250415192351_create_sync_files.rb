class CreateSyncFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :sync_files do |t|
      t.string :file_name
      t.string :file_path
      t.integer :size
      t.datetime :file_created_date
      t.datetime :file_modified_date
      t.integer :workspace_id
      t.integer :sync_id
      t.integer :sync_run_id
      t.integer :status
      t.jsonb :metadata
      t.string :file_type

      t.timestamps
    end

    add_index :sync_files, :workspace_id
    add_index :sync_files, :sync_id
    add_index :sync_files, :sync_run_id
  end
end
