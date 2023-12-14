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
    end
  end
end
