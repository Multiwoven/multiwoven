# frozen_string_literal: true

module ReverseEtl
  module Extractors
    class Base
      DEFAULT_OFFSET = 0
      DEFAULT_BATCH_SIZE = 1000
      DEFAULT_LIMT = 1000

      def read(_sync_run_id)
        raise "Not implemented"
      end

      private

      def batch_params(client, sync_config)
        {
          offset: DEFAULT_OFFSET,
          limit: DEFAULT_LIMT,
          batch_size: DEFAULT_BATCH_SIZE,
          sync_config:,
          client:
        }
      end
    end
  end
end
