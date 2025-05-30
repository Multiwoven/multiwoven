# frozen_string_literal: true

# This migration comes from acts_as_taggable_on_engine (originally 7)
class AddTenantToTaggings < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def self.up
    # Increase statement timeout to avoid lock timeout issues
    safety_assured {
      execute('SET statement_timeout = 300000') # 5 minutes
    }

    # Add column only if it doesn't exist
    unless column_exists?(ActsAsTaggableOn.taggings_table, :tenant)
      add_column ActsAsTaggableOn.taggings_table, :tenant, :string, limit: 128
    end

    # Add index with proper existence check
    unless index_exists?(ActsAsTaggableOn.taggings_table, [:tenant])
      add_index ActsAsTaggableOn.taggings_table, :tenant, algorithm: :concurrently
    end
  end

  def self.down
    # Only remove index if it exists
    if index_exists?(ActsAsTaggableOn.taggings_table, [:tenant])
      remove_index ActsAsTaggableOn.taggings_table, :tenant
    end
    
    # Only remove column if it exists
    if column_exists?(ActsAsTaggableOn.taggings_table, :tenant)
      remove_column ActsAsTaggableOn.taggings_table, :tenant
    end
  end
end
