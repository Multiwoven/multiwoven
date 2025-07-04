# frozen_string_literal: true

# This migration comes from acts_as_taggable_on_engine (originally 3)
class AddTaggingsCounterCacheToTags < ActiveRecord::Migration[7.1]
  def self.up
    # Add column only if it doesn't exist
    unless column_exists?(ActsAsTaggableOn.tags_table, :taggings_count)
      add_column ActsAsTaggableOn.tags_table, :taggings_count, :integer, default: 0

      # Only update counters if we added the column
      safety_assured do
        ActsAsTaggableOn::Tag.reset_column_information
        ActsAsTaggableOn::Tag.find_each do |tag|
          ActsAsTaggableOn::Tag.reset_counters(tag.id, ActsAsTaggableOn.taggings_table)
        end
      end
    end
  end

  def self.down
    # Only remove column if it exists
    if column_exists?(ActsAsTaggableOn.tags_table, :taggings_count)
      remove_column ActsAsTaggableOn.tags_table, :taggings_count
    end
  end
end
