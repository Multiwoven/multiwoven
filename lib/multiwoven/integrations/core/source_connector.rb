# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    # TODO: enforce method signatures using sorbet
    class SourceConnector < BaseConnector
      def discover(_connection_config)
        raise "Not implemented"
        # return catalog
      end

      # TODO: model or query based not sync config
      def read(_sync_config)
        raise "Not implemented"
        # return list of record message
      end
    end
  end
end
