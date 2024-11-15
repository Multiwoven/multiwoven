# frozen_string_literal: true

module Utils
  module PayloadGenerator
    module AiMl
      def self.generate_payload(configuration, harvest_values)
        result = {}

        configuration.each do |config|
          path = config["name"].split(".")
          value = fetch_value(config, harvest_values)
          build_nested_hash(result, path, value)
        end

        result
      end

      def self.build_nested_hash(current, path, value)
        path.each_with_index do |key, index|
          key = convert_key(key)

          if index == path.length - 1
            current[key] = value
          else
            next_key = convert_key(path[index + 1])
            current[key] ||= next_key.is_a?(Integer) ? [] : {}
            current = current[key]
          end
        end
      end

      def self.convert_key(key)
        key.match?(/^\d+$/) ? key.to_i : key
      end

      def self.fetch_value(hash, harvest_values)
        if hash["value_type"] == "static"
          cast_value(hash["value"], hash["type"])
        else
          cast_value(harvest_values[hash["value"]], hash["type"])
        end
      end

      def self.cast_value(value, type)
        case type
        when "string"
          value.to_s
        when "number"
          value.to_i
        when "boolean"
          value == "true"
        else
          value
        end
      end
    end
  end
end
