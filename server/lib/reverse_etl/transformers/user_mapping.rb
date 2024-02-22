# frozen_string_literal: true

module ReverseEtl
  module Transformers
    class UserMapping < Base
      def transform(sync, sync_record)
        mapping = sync.configuration
        record = sync_record.record
        transform_record(record, mapping)
      rescue StandardError => e
        Temporal.logger.error(error_message: e.message,
                              sync_run_id: sync_run.id,
                              stack_trace: Rails.backtrace_cleaner.clean(e.backtrace))
      end

      private

      def transform_record(source_data, mapping) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        destination_data = {}

        mapping.each do |source_key, dest_path|
          dest_keys = dest_path.split(".")
          current = destination_data

          dest_keys.each_with_index do |key, index|
            if index == dest_keys.length - 1
              # Handle array notation in the path
              if key.include?("[]")
                array_key = key.gsub("[]", "")
                current[array_key] ||= []
                current[array_key] << source_data[source_key]
              else
                current[key] = source_data[source_key]
              end
            elsif key.include?("[]")
              array_key = key.gsub("[]", "")
              current[array_key] ||= []
              # Use the last element of the array or create a new one if empty
              current = current[array_key].last || current[array_key].push({}).last
            else
              current[key] ||= {}
              current = current[key]
            end
          end
        end

        destination_data
      end
    end
  end
end
