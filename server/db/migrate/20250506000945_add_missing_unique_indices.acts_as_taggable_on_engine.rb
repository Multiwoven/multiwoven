# frozen_string_literal: true

# This migration comes from acts_as_taggable_on_engine (originally 2)
class AddMissingUniqueIndices < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!
  
  def self.up
    # Increase statement timeout to avoid lock timeout issues
    safety_assured { execute('SET statement_timeout = 300000') } # 5 minutes

    add_index ActsAsTaggableOn.tags_table, :name, unique: true, algorithm: :concurrently

    remove_index ActsAsTaggableOn.taggings_table, :tag_id if index_exists?(ActsAsTaggableOn.taggings_table, :tag_id)
    remove_index ActsAsTaggableOn.taggings_table, name: 'taggings_taggable_context_idx'
    add_index ActsAsTaggableOn.taggings_table,
              %i[tag_id taggable_id taggable_type context tagger_id tagger_type],
              unique: true, name: 'taggings_idx', algorithm: :concurrently
  end

  def self.down
    remove_index ActsAsTaggableOn.tags_table, :name

    remove_index ActsAsTaggableOn.taggings_table, name: 'taggings_idx'

    add_index ActsAsTaggableOn.taggings_table, :tag_id unless index_exists?(ActsAsTaggableOn.taggings_table, :tag_id)
    add_index ActsAsTaggableOn.taggings_table, %i[taggable_id taggable_type context],
              name: 'taggings_taggable_context_idx'
  end
end
