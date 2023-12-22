# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class DestinationConnector < BaseConnector
      def write(_sync_config, _records, _action = "insert")
        raise "Not implemented"
        # return list of record message
      end
    end
  end
end
