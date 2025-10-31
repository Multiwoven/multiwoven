class CreateHostedDataStoreTable < ActiveRecord::Migration[7.1]
  def up
    create_table :hosted_data_store_tables do |t|
      t.integer :hosted_data_store_id
      t.string :name
      t.integer :column_count
      t.integer :row_count
      t.integer :size
      t.integer :sync_enabled
      t.integer :source_connector_id
      t.integer :destination_connector_id
      t.jsonb :table_schema, default: {}

      t.timestamps
    end

    # Add the foreign key only if the parent table exists
    if table_exists?(:hosted_data_stores)
      add_foreign_key :hosted_data_store_tables, :hosted_data_stores,
                      on_delete: :cascade,
                      validate: false
    end
  end

  def down
    remove_foreign_key :hosted_data_store_tables, :hosted_data_stores rescue nil
    drop_table :hosted_data_store_tables, if_exists: true
  end
end
