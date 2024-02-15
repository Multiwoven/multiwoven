# frozen_string_literal: true

module ReverseEtl
  module Extractors
    class Base
      DEFAULT_OFFSET = 0
      DEFAULT_BATCH_SIZE = (ENV["SYNC_EXTRACTOR_BATCH_SIZE"] || "1000").to_i
      DEFAULT_LIMT = (ENV["SYNC_EXTRACTOR_BATCH_SIZE"] || "1000").to_i

      def read(_sync_run_id)
        raise "Not implemented"
      end

      private

      def batch_params(client, sync_run)
        {
          offset: sync_run.current_offset || DEFAULT_OFFSET,
          limit: DEFAULT_LIMT,
          batch_size: DEFAULT_BATCH_SIZE,
          sync_config: sync_run.sync.to_protocol,
          client:
        }
      end
    end
  end
end
