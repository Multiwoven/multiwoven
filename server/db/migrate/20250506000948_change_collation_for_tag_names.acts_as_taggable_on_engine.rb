# frozen_string_literal: true

# This migration comes from acts_as_taggable_on_engine (originally 5)
# This migration is added to circumvent issue #623 and have special characters
# work properly

class ChangeCollationForTagNames < ActiveRecord::Migration[7.1]
  def up
    # Only apply on MySQL and only if the tags table exists
    if ActsAsTaggableOn::Utils.using_mysql? && ActiveRecord::Base.connection.table_exists?(ActsAsTaggableOn.tags_table)
      # Check if the name column exists before modifying it
      if ActiveRecord::Base.connection.column_exists?(ActsAsTaggableOn.tags_table, :name)
        safety_assured { 
          # Increase statement timeout to avoid lock timeout issues
          execute('SET statement_timeout = 300000') # 5 minutes
          execute("ALTER TABLE #{ActsAsTaggableOn.tags_table} MODIFY name varchar(255) CHARACTER SET utf8 COLLATE utf8_bin;") 
        }
      end
    end
  end

  def down
    # Only apply on MySQL and only if the tags table exists
    if ActsAsTaggableOn::Utils.using_mysql? && ActiveRecord::Base.connection.table_exists?(ActsAsTaggableOn.tags_table)
      # Check if the name column exists before modifying it
      if ActiveRecord::Base.connection.column_exists?(ActsAsTaggableOn.tags_table, :name)
        safety_assured { 
          # Increase statement timeout to avoid lock timeout issues
          execute('SET statement_timeout = 300000') # 5 minutes
          execute("ALTER TABLE #{ActsAsTaggableOn.tags_table} MODIFY name varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci;") 
        }
      end
    end
  end
end
