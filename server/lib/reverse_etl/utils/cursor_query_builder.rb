# frozen_string_literal: true

module ReverseEtl
  module Utils
    class CursorQueryBuilder
      def self.build_cursor_query(sync_config, current_cursor_field)
        existing_query = sync_config.model.query
        query_type = sync_config.source.query_type || "raw_sql"

        cursor_condition = build_cursor_condition(sync_config.cursor_field, current_cursor_field, query_type)
        case query_type.to_sym
        when :soql
          if cursor_condition.present?
            where_clause = existing_query.include?("WHERE") ? " AND #{cursor_condition}" : " WHERE #{cursor_condition}"
            "#{existing_query}#{where_clause} ORDER BY #{sync_config.cursor_field} ASC"
          else
            "#{existing_query} ORDER BY #{sync_config.cursor_field} ASC"
          end
        when :raw_sql
          if cursor_condition.present?
            "#{existing_query} AS subquery " \
            "WHERE #{cursor_condition} " \
            "ORDER BY #{sync_config.cursor_field} ASC"
          else
            "#{existing_query} AS subquery " \
            "ORDER BY #{sync_config.cursor_field} ASC"
          end
        end
      end

      def self.build_cursor_condition(cursor_field, current_cursor_field, query_type)
        return "" unless current_cursor_field

        case query_type.to_sym
        when :soql
          "#{cursor_field} >= #{current_cursor_field}"
        when :raw_sql
          "#{cursor_field} >= '#{current_cursor_field}'"
        else
          ""
        end
      end
    end
  end
end
