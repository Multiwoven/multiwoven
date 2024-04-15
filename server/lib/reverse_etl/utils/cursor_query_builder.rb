# frozen_string_literal: true

module ReverseEtl
  module Utils
    class CursorQueryBuilder
      def self.update_model_query(sync_config, current_cursor_field)
        existing_query = sync_config.model.query
        if sync_config.cursor_field && current_cursor_field
          "#{existing_query} AS subquery " \
          "WHERE #{sync_config.cursor_field} >= #{current_cursor_field} " \
          "ORDER BY #{sync_config.cursor_field} ASC"
        elsif sync_config.cursor_field
          "#{existing_query} AS subquery " \
          "ORDER BY #{sync_config.cursor_field} ASC"
        else
          sync_config.model.query
        end
      end
    end
  end
end
