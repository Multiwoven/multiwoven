class CreateKnowledgeBaseFile < ActiveRecord::Migration[7.1]
  def change
    create_table :knowledge_base_files do |t|
      t.string :name
      t.integer :size, default: 0
      t.string :status, default: "processing"
      t.integer :first_record_id
      t.integer :last_record_id
      t.integer :knowledge_base_id
      t.boolean :workflow_enabled, default: false

      t.timestamps
    end
  end
end
