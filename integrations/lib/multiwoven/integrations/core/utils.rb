# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    module Utils
      def keys_to_symbols(hash)
        if hash.is_a?(Hash)
          hash.each_with_object({}) do |(key, value), result|
            result[key.to_sym] = keys_to_symbols(value)
          end
        elsif hash.is_a?(Array)
          hash.map { |item| keys_to_symbols(item) }
        else
          hash
        end
      end

      def convert_to_json_schema(column_definitions)
        json_schema = {
          "type" => "object",
          "properties" => {}
        }

        column_definitions.each do |column|
          column_name = column[:column_name]
          type = column[:type]
          optional = column[:optional]
          json_type = map_type_to_json_schema(type)
          json_schema["properties"][column_name] = {
            "type" => json_type
          }
          json_schema["properties"][column_name]["type"] = [json_type, "null"] if optional
        end

        json_schema
      end

      def map_type_to_json_schema(type)
        case type
        when "NUMBER"
          "integer"
        else
          "string" # Default type
        end
      end

      def logger
        Integrations::Service.logger
      end

      def report_exception(exception, meta = {})
        reporter = Integrations::Service.exception_reporter
        reporter&.report(exception, meta)
      end

      def log_request_response(level, request, response)
        Integrations::Protocol::LogMessage.new(
          name: self.class.name,
          level: level,
          message: { request: request.to_s, response: response.to_s, level: level }.to_json
        )
      end

      def create_log_message(context, type, exception)
        Integrations::Protocol::LogMessage.new(
          name: context,
          level: type,
          message: exception.message
        ).to_multiwoven_message
      end

      def handle_exception(exception, meta = {})
        logger.error(
          "#{hash_to_string(meta)}: #{exception.message}"
        )
        report_exception(exception, meta)
        create_log_message(meta[:context], meta[:type], exception)
      end

      def hash_to_string(hash)
        hash.map { |key, value| "#{key} = #{value}" }.join(", ")
      end

      def extract_data(record_object, properties)
        data_attributes = record_object.with_indifferent_access
        data_attributes.select { |key, _| properties.key?(key.to_sym) }
      end

      def success?(response)
        response && %w[200 201].include?(response.code.to_s)
      end

      def build_catalog(catalog_json)
        streams = catalog_json["streams"].map { |stream_json| build_stream(stream_json) }
        Multiwoven::Integrations::Protocol::Catalog.new(
          streams: streams,
          request_rate_limit: catalog_json["request_rate_limit"] || 60,
          request_rate_limit_unit: catalog_json["request_rate_limit_unit"] || "minute",
          request_rate_concurrency: catalog_json["request_rate_concurrency"] || 10,
          schema_mode: catalog_json["schema_mode"] || "schema"
        )
      end

      def build_stream(stream_json)
        Multiwoven::Integrations::Protocol::Stream.new(
          name: stream_json["name"],
          url: stream_json["url"],
          action: stream_json["action"],
          request_method: stream_json["method"],
          batch_support: stream_json["batch_support"] || false,
          batch_size: stream_json["batch_size"] || 1,
          json_schema: stream_json["json_schema"],
          request_rate_limit: stream_json["request_rate_limit"].to_i,
          request_rate_limit_unit: stream_json["request_rate_limit_unit"] || "minute",
          request_rate_concurrency: stream_json["request_rate_concurrency"].to_i,
          supported_sync_modes: stream_json["supported_sync_modes"]
        )
      end
    end
  end
end
