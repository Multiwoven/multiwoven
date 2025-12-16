class UpdateStatusForKnowledgeBaseFile < ActiveRecord::Migration[7.1]
  def up
    if column_exists?(:knowledge_base_files, :status)
      safety_assured { remove_column :knowledge_base_files, :status }
      add_column :knowledge_base_files, :upload_status, :integer, default: 0
    end
  end

  def down
    if column_exists?(:knowledge_base_files, :upload_status)
      safety_assured { remove_column :knowledge_base_files, :upload_status }
      add_column :knowledge_base_files, :status, :string, default: "processing"
    end
  end
end
