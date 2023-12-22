# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class SourceConnector < BaseConnector
      def read(_sync_config)
        raise "Not implemented"
        # return list of RecordMessage
      end
    end
  end
end
