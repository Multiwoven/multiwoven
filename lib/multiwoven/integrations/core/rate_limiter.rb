# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    module RateLimiter
      def write(sync_config, records, action = "insert")
        stream = sync_config.stream

        @queue ||= Limiter::RateQueue.new(stream.request_rate_limit, interval: stream.rate_limit_unit_seconds) do
          puts "Hit the limit, waiting"
        end

        @queue.shift

        super(sync_config, records, action)
      end
    end
  end
end
