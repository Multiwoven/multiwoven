# frozen_string_literal: true

module ReverseEtl
  module Utils
    class CursorQueryBuilder
      def self.build_cursor_query(sync_config, current_cursor_field)
        existing_query = sync_config.model.query
        query_type = sync_config.source.query_type || "raw_sql"
        if current_cursor_field
          cursor_condition = case query_type.to_sym
                             when :soql
                               "#{sync_config.cursor_field} >= #{current_cursor_field}"
                             when :raw_sql
                               "#{sync_config.cursor_field} >= '#{current_cursor_field}'"
                             end
        end
        if cursor_condition
          "#{existing_query} AS subquery " \
          "WHERE #{cursor_condition} " \
          "ORDER BY #{sync_config.cursor_field} ASC"
        elsif sync_config.cursor_field
          "#{existing_query} AS subquery " \
          "ORDER BY #{sync_config.cursor_field} ASC"
        end
      end
    end
  end
end
