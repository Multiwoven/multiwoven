class AddFileNameToKnowledgeBaseFile < ActiveRecord::Migration[7.1]
  def up
    safety_assured { remove_column :knowledge_base_files, :first_record_id if column_exists?(:knowledge_base_files, :first_record_id) }
    safety_assured { remove_column :knowledge_base_files, :last_record_id if column_exists?(:knowledge_base_files, :last_record_id) }

    # Add foreign key only if both tables exist
    if table_exists?(:workspaces)
      add_foreign_key :knowledge_bases, :workspaces, validate: false
    end

    if table_exists?(:knowledge_bases)
      add_foreign_key :knowledge_base_files, :knowledge_bases, column: :knowledge_base_id, validate: false
    end
  end

  def down
    add_column :knowledge_base_files, :first_record_id, :integer unless column_exists?(:knowledge_base_files, :first_record_id)
    add_column :knowledge_base_files, :last_record_id, :integer unless column_exists?(:knowledge_base_files, :last_record_id)
    remove_foreign_key :knowledge_bases, :workspaces rescue nil
    remove_foreign_key :knowledge_base_files, :knowledge_bases, column: :knowledge_base_id rescue nil
  end
end
