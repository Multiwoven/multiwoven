# frozen_string_literal: true

module ReverseEtl
  module Utils
    class CursorQueryBuilder
      # Column or dotted/qualified path (e.g. updated_at, schema.col, Account.Name__c).
      # Rejects spaces, quotes, semicolons, and other characters that enable injection.
      SAFE_CURSOR_FIELD = /\A[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*\z/

      # SOQL allows unquoted number / date / datetime literals; everything else must be a
      # single-quoted string (with ' escaped as ''). See Salesforce SOQL literal types.
      SOQL_UNQUOTED_LITERAL = /
        \A(?:
          -?\d+(?:\.\d+)?
          |
          \d{4}-\d{2}-\d{2}
          (?:T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?)?
        )\z
      /x

      # rubocop:disable Metrics/CyclomaticComplexity
      def self.build_cursor_query(sync_config, current_cursor_field)
        existing_query = sync_config.model.query
        query_type = sync_config.source.query_type || "raw_sql"
        return existing_query if sync_config.cursor_field.blank?

        cursor_field = sanitize_cursor_field!(sync_config.cursor_field)
        cursor_condition = build_cursor_condition(cursor_field, current_cursor_field, query_type)
        case query_type.to_sym
        when :soql
          if cursor_condition.present?
            where_clause = existing_query.include?("WHERE") ? " AND #{cursor_condition}" : " WHERE #{cursor_condition}"
            "#{existing_query}#{where_clause} ORDER BY #{cursor_field} ASC"
          else
            "#{existing_query} ORDER BY #{cursor_field} ASC"
          end
        when :raw_sql
          # Wrap arbitrary SQL (including CTEs) so ORDER BY / WHERE apply to the result set.
          # Bare "... AS subquery ORDER BY ..." only works for simple "FROM table" queries.
          wrapped_query = existing_query.to_s.sub(/;?\s*\z/, "")
          order_by = "ORDER BY #{cursor_field} ASC"
          where_clause = cursor_condition.present? ? "WHERE #{cursor_condition} " : ""
          "SELECT * FROM (#{wrapped_query}) AS subquery #{where_clause}#{order_by}"
        else
          # Cursor rewriting is only defined for soql/raw_sql; leave the query unchanged
          # rather than returning nil into sync configs.
          existing_query
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def self.build_cursor_condition(cursor_field, current_cursor_field, query_type)
        return "" unless current_cursor_field

        case query_type.to_sym
        when :soql
          "#{cursor_field} >= #{format_soql_literal(current_cursor_field)}"
        when :raw_sql
          escaped = current_cursor_field.to_s.gsub("'", "''")
          "#{cursor_field} >= '#{escaped}'"
        else
          ""
        end
      end

      def self.format_soql_literal(value)
        literal = value.to_s
        return literal if literal.match?(SOQL_UNQUOTED_LITERAL)

        "'#{literal.gsub("'", "''")}'"
      end

      def self.sanitize_cursor_field!(cursor_field)
        field = cursor_field.to_s
        return field if field.match?(SAFE_CURSOR_FIELD)

        raise ArgumentError, "Invalid cursor_field: #{cursor_field.inspect}"
      end
      private_class_method :sanitize_cursor_field!, :format_soql_literal
    end
  end
end
