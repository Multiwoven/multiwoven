# frozen_string_literal: true

module ReverseEtl
  module Utils
    class CursorQueryBuilder
      def self.update_model_query(sync_config)
        existing_query = sync_config.model.query

        if sync_config.cursor_field && sync_config.current_cursor_field
          new_query = "(#{existing_query}) AS subquery " \
          "WHERE #{sync_config.cursor_field} >= '#{sync_config.current_cursor_field}' " \
          "ORDER BY #{sync_config.cursor_field} ASC"
        elsif sync_config.cursor_field
          new_query = "(#{existing_query}) AS subquery " \
          "ORDER BY #{sync_config.cursor_field} ASC"
        else
          return sync_config
        end

        build_sync_config(sync_config, new_query)
      end

      def self.build_sync_config(sync_config, new_query)
        new_model = build_new_model(sync_config.model, new_query)

        Multiwoven::Integrations::Protocol::SyncConfig.new(
          model: new_model.to_protocol,
          source: sync_config.source,
          destination: sync_config.destination,
          stream: sync_config.stream,
          sync_mode: sync_config.sync_mode,
          destination_sync_mode: sync_config.destination_sync_mode,
          cursor_field: sync_config.cursor_field,
          current_cursor_field: sync_config.current_cursor_field
        )
      end

      def self.build_new_model(existing_model, new_query)
        Model.new(
          name: existing_model.name,
          query: new_query,
          query_type: existing_model.query_type,
          primary_key: existing_model.primary_key
        )
      end
    end
  end
end
