# frozen_string_literal: true

module Utils
  module SecretMasking
    MASKED_VALUE = "*************"

    module_function

    def mask_by_keys(config, schema)
      secret_keys = extract_secret_keys(schema)
      return config if secret_keys.empty?

      mask_values(config, secret_keys)
    end

    def mask_nested_values(obj)
      case obj
      when Hash
        obj.transform_values { |v| mask_nested_values(v) }
      when Array
        obj.map { |v| mask_nested_values(v) }
      when String
        obj.present? ? MASKED_VALUE : obj
      else
        obj
      end
    end

    def mask_values(config, secret_keys)
      case config
      when Hash
        config.each_with_object({}) do |(key, value), result|
          result[key] = if secret_keys.include?(key.to_s)
                          MASKED_VALUE
                        else
                          mask_values(value, secret_keys)
                        end
        end
      when Array
        config.map { |item| mask_values(item, secret_keys) }
      else
        config
      end
    end

    def extract_secret_keys(schema, keys = [])
      return keys unless schema.is_a?(Hash)

      schema = schema.with_indifferent_access
      (schema["properties"] || {}).each do |key, subschema|
        keys << key.to_s if subschema["multiwoven_secret"]
        extract_secret_keys(subschema, keys)
      end

      extract_secret_keys(schema["items"], keys) if schema["items"]

      keys
    end

    private_class_method :extract_secret_keys, :mask_values
  end
end
