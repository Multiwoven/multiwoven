# frozen_string_literal: true

# This migration comes from acts_as_taggable_on_engine (originally 4)
class AddMissingTaggableIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def self.up
    add_index ActsAsTaggableOn.taggings_table, %i[taggable_id taggable_type context],
              name: 'taggings_taggable_context_idx', algorithm: :concurrently
  end

  def self.down
    remove_index ActsAsTaggableOn.taggings_table, name: 'taggings_taggable_context_idx'
  end
end
