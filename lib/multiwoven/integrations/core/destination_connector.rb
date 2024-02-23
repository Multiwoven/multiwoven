# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class DestinationConnector < BaseConnector
      prepend RateLimiter

      # Records are transformed json payload send it to the destination
      # SyncConfig is the Protocol::SyncConfig object
      def write(_sync_config, _records, _action = "insert")
        raise "Not implemented"
        # return Protocol::TrackingMessage
      end
    end
  end
end
