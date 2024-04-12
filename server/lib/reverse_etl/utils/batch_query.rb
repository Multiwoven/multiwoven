# frozen_string_literal: true

module ReverseEtl
  module Utils
    class BatchQuery
      def self.execute_in_batches(params)
        raise ArgumentError, "Batch size must be greater than 0" if params[:batch_size] <= 0

        current_offset = params[:offset]

        loop do
          # Set the current limit and offset in the sync configuration
          params[:sync_config].limit = params[:batch_size]
          params[:sync_config].offset = current_offset

          CursorQueryBuilder.update_query(params[:sync_config])

          # Execute the batch query
          result = params[:client].read(params[:sync_config])

          # Extract the value of the cursor_field column from the last record
          last_cursor_field_value = nil
          if params[:sync_config].cursor_field && !result.empty?
            last_record = result.last.message.record.data
            last_cursor_field_value = last_record[params[:sync_config].cursor_field]
          end

          # Increment the offset by the batch size for the next iteration
          current_offset += params[:batch_size]

          break if result.empty?

          yield result, current_offset, last_cursor_field_value if block_given?
          # Break the loop if the number of records fetched is less than the batch size
          # break if result.size < params[:batch_size]
        end
      end
    end
  end
end
