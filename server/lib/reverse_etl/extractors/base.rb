# frozen_string_literal: true

module ReverseEtl
  module Extractors
    class Base
      DEFAULT_OFFSET = 0
      DEFAULT_BATCH_SIZE = (ENV["SYNC_EXTRACTOR_BATCH_SIZE"] || "10000").to_i
      DEFAULT_LIMT = (ENV["SYNC_EXTRACTOR_BATCH_SIZE"] || "10000").to_i
      THREAD_COUNT = (ENV["SYNC_EXTRACTOR_THREAD_POOL_SIZE"] || "5").to_i

      def read(_sync_run_id)
        raise "Not implemented"
      end

      private

      def heartbeat(activity)
        activity.heartbeat
        raise StandardError, "Cancel activity request received" if activity.cancel_requested
      end

      def setup_source_client(sync)
        sync.source.connector_client.new
      end

      def generate_fingerprint(data)
        Digest::SHA1.hexdigest(data.to_json)
      end

      def batch_params(client, sync_run)
        {
          offset: sync_run.current_offset || DEFAULT_OFFSET,
          limit: DEFAULT_LIMT,
          batch_size: DEFAULT_BATCH_SIZE,
          sync_config: sync_run.sync.to_protocol,
          client:
        }
      end

      def log_sync_run_error(sync_run)
        Temporal.logger.error(
          error_message: "SyncRun cannot querying from its current state: #{sync_run.status}",
          sync_run_id: sync_run.id,
          stack_trace: nil
        )
      end
    end
  end
end
