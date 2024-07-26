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

      def heartbeat(activity, sync_run, initial_cursor_field_value)
        response = activity.heartbeat
        return unless response.cancel_requested

        sync_run.failed!
        sync_run.sync.update(current_cursor_field: initial_cursor_field_value)
        sync_run.sync_records.delete_all
        Rails.logger.error({
          error_message: "Cancel activity request received",
          sync_run_id: sync_run.id,
          sync_id: sync_run.sync_id,
          stack_trace: nil
        }.to_s)
        raise StandardError, "Cancel activity request received"
      end

      def setup_source_client(sync)
        sync.source.connector_client.new
      end

      def generate_fingerprint(data)
        Digest::SHA1.hexdigest(data.to_json)
      end

      def batch_params(client, sync_run)
        sync_config = sync_run.sync.to_protocol
        sync_config.sync_run_id = sync_run.id.to_s
        {
          offset: sync_run.current_offset || DEFAULT_OFFSET,
          limit: DEFAULT_LIMT,
          batch_size: DEFAULT_BATCH_SIZE,
          sync_config:,
          client:
        }
      end

      def log_sync_run_error(sync_run)
        Rails.logger.error({
          error_message: "SyncRun cannot querying from its current state: #{sync_run.status}",
          sync_run_id: sync_run.id,
          stack_trace: nil
        }.to_s)
      end
    end
  end
end
