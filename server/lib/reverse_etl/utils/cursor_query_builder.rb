# frozen_string_literal: true

module ReverseEtl
  module Utils
    class CursorQueryBuilder
      def self.update_query(sync_config)
        if sync_config.cursor_field && sync_config.current_cursor_field
          # If both cursor_field and current_cursor_field are present
          sync_config.model.query = "(#{existing_query}) AS subquery
            WHERE #{sync_config.cursor_field} >= '#{sync_config.current_cursor_field}'
            ORDER BY #{sync_config.cursor_field} ASC"
        elsif sync_config.cursor_field
          # If only cursor_field is present but current_cursor_field is not
          sync_config.model.query = "(#{existing_query}) AS subquery
            ORDER BY #{sync_config.cursor_field} ASC"
        end
      end
    end
  end
end
