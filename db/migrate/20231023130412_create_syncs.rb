class CreateSyncs < ActiveRecord::Migration[7.1]
  def change
    create_table :syncs do |t|
      t.integer :workspace_id
      t.integer :source_id
      t.integer :model_id
      t.integer :destination_id
      t.jsonb :configuration
      t.integer :source_catalog_id
      t.integer :schedule_type
      t.jsonb :schedule_data
      t.integer :status

      t.timestamps
    end
  end
end
