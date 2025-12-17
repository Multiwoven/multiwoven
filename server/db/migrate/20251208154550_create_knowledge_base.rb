class CreateKnowledgeBase < ActiveRecord::Migration[7.1]
  def change
    create_table :knowledge_bases do |t|
      t.string :name
      t.integer :knowledge_base_type
      t.integer :size, default: 0
      t.jsonb :embedding_config
      t.jsonb :storage_config
      t.integer :source_connector_id
      t.integer :destination_connector_id
      t.integer :hosted_data_store_id, null: true
      t.integer :workspace_id

      t.timestamps
    end
  end
end
