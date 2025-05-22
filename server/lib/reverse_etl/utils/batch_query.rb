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

          if initial_sync_config.cursor_field.present?
            query_with_cursor = CursorQueryBuilder.build_cursor_query(initial_sync_config, last_cursor_field_value)
            params[:sync_config] = build_cursor_sync_config(params[:sync_config], query_with_cursor)
          end

          # Execute the batch query
          result = params[:client].read(params[:sync_config])
          
          # Check if result is an error message
          if result.is_a?(Multiwoven::Integrations::Protocol::MultiwovenMessage) && result.type == 'log'
            Rails.logger.error("Error in batch query: #{result.log.message}")
            # Return empty array to break the loop
            result = []
          else
            # Extract the value of the cursor_field column from the last record
            current_cursor_field_value = extract_last_cursor_field_value(result, params[:sync_config])
            if current_cursor_field_value && current_cursor_field_value == last_cursor_field_value
              result = []
            else
              last_cursor_field_value = current_cursor_field_value
            end
          end
          # Increment the offset by the batch size for the next iteration
          current_offset += params[:batch_size]

          break if result.empty?

          yield result, current_offset, last_cursor_field_value if block_given?
          # Break the loop if the number of records fetched is less than the batch size
          # break if result.size < params[:batch_size]
        end
      end

      def self.extract_last_cursor_field_value(result, sync_config)
        # Handle the case when result is a MultiwovenMessage with a LogMessage (error case)
        return nil if result.nil? || result.is_a?(Multiwoven::Integrations::Protocol::MultiwovenMessage) && result.type == 'log'
        
        # Handle the case when result is an array-like object
        return nil unless sync_config.cursor_field && result.respond_to?(:empty?) && !result.empty? && result.respond_to?(:last)

        # Make sure the last record has a record attribute with data
        last_item = result.last
        return nil unless last_item.respond_to?(:record) && last_item.record.respond_to?(:data)

        last_record = last_item.record.data
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
          current_cursor_field: sync_config.current_cursor_field,
          sync_id: sync_config.sync_id
        )
        modified_sync_config.offset = 0
        modified_sync_config.limit = sync_config.limit
        modified_sync_config.sync_run_id = sync_config.sync_run_id
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
