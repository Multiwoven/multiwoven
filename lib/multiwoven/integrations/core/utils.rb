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
    end
  end
end
