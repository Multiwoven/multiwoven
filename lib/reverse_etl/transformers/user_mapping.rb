# frozen_string_literal: true

module ReverseEtl
  module Transformers
    class UserMapping < Base
      attr_accessor :mappings, :record, :destination_data

      def transform(sync, sync_record)
        @mappings = sync.configuration
        @record = sync_record.record
        @destination_data = {}

        if mappings.is_a?(Array)
          transform_record_v2
        else
          transform_record_v1
        end

        @destination_data
      rescue StandardError => e
        Temporal.logger.error(error_message: e.message,
                              sync_run_id: sync_run.id,
                              stack_trace: Rails.backtrace_cleaner.clean(e.backtrace))
      end

      private

      def transform_record_v1
        mappings.each do |source_key, dest_path|
          dest_keys = dest_path.split(".")
          mapped_destination_value = record[source_key]
          extract_destination_mapping(dest_keys, mapped_destination_value)
        end
      end

      def transform_record_v2
        mappings.each do |mapping|
          mapping = mapping.with_indifferent_access
          case mapping[:mapping_type]
          when "standard"
            standard_mapping(mapping)
          when "static"
            static_mapping(mapping)
          when "template"
            template_mapping(mapping)
          end
        end
      end

      def standard_mapping(mapping)
        dest_keys = mapping[:to].split(".")
        source_key = mapping[:from]
        mapped_destination_value = record[source_key]
        extract_destination_mapping(dest_keys, mapped_destination_value)
      end

      def static_mapping(mapping)
        dest_keys = mapping[:to].split(".")
        static_value = mapping[:from]
        extract_destination_mapping(dest_keys, static_value)
      end

      def template_mapping(mapping)
        dest_keys = mapping[:to].split(".")
        template = mapping[:from]
        Liquid::Template.register_filter(Liquid::CustomFilters)
        liquid_template = Liquid::Template.parse(template)
        rendered_text = liquid_template.render(record)
        extract_destination_mapping(dest_keys, rendered_text)
      end

      def extract_destination_mapping(dest_keys, mapped_destination_value)
        current = destination_data

        dest_keys.each_with_index do |key, index|
          is_last_key = index == dest_keys.length - 1
          is_array_key = key.include?("[]")

          if is_last_key
            # Handle array notation in the path
            set_value(current, key, mapped_destination_value, is_array_key)
          elsif is_array_key
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

      def set_value(current, key, value, is_array)
        if is_array
          array_key = key.gsub("[]", "")
          current[array_key] ||= []
          current[array_key] << value
        else
          current[key] = value
        end
      end
    end
  end
end
