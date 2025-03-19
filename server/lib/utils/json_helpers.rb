# frozen_string_literal: true

module Utils
  module JsonHelpers
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def resolve_values_from_env(json_hash)
      return {} if json_hash.nil?

      json_hash.transform_values do |value|
        if value.is_a?(Hash)
          resolve_values_from_env(value)
        elsif value.is_a?(String) && value.match?(/ENV\['[^']*'\]/)
          env_var = value.match(/ENV\['([^']*)'\]/)[1]
          ENV[env_var]
        elsif value.is_a?(String) && value.match?(/ENV\["[^"]*"\]/)
          env_var = value.match(/ENV\["([^"]*)"\]/)[1]
          ENV[env_var]
        else
          value
        end
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
