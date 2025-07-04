class AddMissingUniqueIndices < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!
  
  def self.up
    # Increase statement timeout to avoid lock timeout issues
    safety_assured {
      execute('SET statement_timeout = 300000') # 5 minutes
    }

    # Add index to tags table name column if it doesn't exist already
    unless index_exists?(ActsAsTaggableOn.tags_table, :name, name: 'index_tags_on_name')
      add_index ActsAsTaggableOn.tags_table, :name, unique: true, algorithm: :concurrently
    end

    remove_index ActsAsTaggableOn.taggings_table, :tag_id if index_exists?(ActsAsTaggableOn.taggings_table, [:tag_id])
    
    if index_exists?(ActsAsTaggableOn.taggings_table, nil, name: 'taggings_taggable_context_idx')
      remove_index ActsAsTaggableOn.taggings_table, name: 'taggings_taggable_context_idx'
    end
    
    # Only add the new index if it doesn't already exist
    unless index_exists?(ActsAsTaggableOn.taggings_table, nil, name: 'taggings_idx')
      add_index ActsAsTaggableOn.taggings_table,
                %i[tag_id taggable_id taggable_type context tagger_id tagger_type],
                unique: true, name: 'taggings_idx', algorithm: :concurrently
    end
  end

  def self.down
    remove_index ActsAsTaggableOn.tags_table, :name if index_exists?(ActsAsTaggableOn.tags_table, [:name])

    remove_index ActsAsTaggableOn.taggings_table, name: 'taggings_idx' if index_exists?(ActsAsTaggableOn.taggings_table, nil, name: 'taggings_idx')

    add_index ActsAsTaggableOn.taggings_table, :tag_id unless index_exists?(ActsAsTaggableOn.taggings_table, [:tag_id])
    
    unless index_exists?(ActsAsTaggableOn.taggings_table, nil, name: 'taggings_taggable_context_idx')
      add_index ActsAsTaggableOn.taggings_table, %i[taggable_id taggable_type context],
                name: 'taggings_taggable_context_idx'
    end
  end
end
