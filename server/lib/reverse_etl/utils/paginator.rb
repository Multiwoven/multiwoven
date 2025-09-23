# frozen_string_literal: true

module ReverseEtl
  module Utils
    class Paginator
      def self.execute_in_batches(params)
        raise ArgumentError, "Batch size must be greater than 0" if params[:batch_size] <= 0

        offset_variable = params[:sync_config].increment_strategy_config.offset_variable
        limit_variable = params[:sync_config].increment_strategy_config.limit_variable
        current_offset = params[offset_variable]
        loop do
          # Set the current limit and offset in the sync configuration
          params[:sync_config].increment_strategy_config.limit = params[limit_variable]
          params[:sync_config].increment_strategy_config.offset = current_offset

          # Execute the batch paginator
          result = params[:client].read(params[:sync_config])
          # Increment the offset by the batch size for the next iteration
          current_offset += params[:batch_size]

          break if result.empty?

          yield result, current_offset if block_given?
          # Break the loop if the number of records fetched is less than the batch size
          # break if result.size < params[:batch_size]
        end
      end
    end
  end
end
