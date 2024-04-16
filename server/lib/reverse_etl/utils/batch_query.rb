# frozen_string_literal: true

module ReverseEtl
  module Utils
    class BatchQuery
      def self.execute_in_batches(params)
        raise ArgumentError, "Batch size must be greater than 0" if params[:batch_size] <= 0

        initial_sync_config = params[:sync_config]
        current_offset = params[:offset]
        last_cursor_field_value = params[:sync_config].current_cursor_field
        loop do
          # Set the current limit and offset in the sync configuration
          params[:sync_config].limit = params[:batch_size]
          params[:sync_config].offset = current_offset

          if initial_sync_config.cursor_field
            query_with_cursor = CursorQueryBuilder.build_cursor_query(initial_sync_config, last_cursor_field_value)
            params[:sync_config] = build_cursor_sync_config(params[:sync_config], query_with_cursor)
          end

          # Execute the batch query
          result = params[:client].read(params[:sync_config])
          # Extract the value of the cursor_field column from the last record
          last_cursor_field_value = extract_last_cursor_field_value(result, params[:sync_config])

          # Increment the offset by the batch size for the next iteration
          current_offset += params[:batch_size]

          break if result.empty?

          yield result, current_offset, last_cursor_field_value if block_given?
          # Break the loop if the number of records fetched is less than the batch size
          # break if result.size < params[:batch_size]
        end
      end

      def self.extract_last_cursor_field_value(result, sync_config)
        return nil unless sync_config.cursor_field && !result.empty?

        last_record = result.last.record.data
        last_record[sync_config.cursor_field]
      end

      def self.build_cursor_sync_config(sync_config, new_query)
        new_model = build_new_model(sync_config.model, new_query)

        modified_sync_config = Multiwoven::Integrations::Protocol::SyncConfig.new(
          model: new_model.to_protocol,
          source: sync_config.source,
          destination: sync_config.destination,
          stream: sync_config.stream,
          sync_mode: sync_config.sync_mode,
          destination_sync_mode: sync_config.destination_sync_mode,
          cursor_field: sync_config.cursor_field,
          current_cursor_field: sync_config.current_cursor_field
        )
        modified_sync_config.offset = 0
        modified_sync_config.limit = sync_config.limit
        modified_sync_config
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
