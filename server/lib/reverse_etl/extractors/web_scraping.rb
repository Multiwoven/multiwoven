# frozen_string_literal: true

module ReverseEtl
  module Extractors
    class WebScraping < Base
      # TODO: Make it as class method
      def read(sync_run_id, activity)
        sync_run = SyncRun.find(sync_run_id)
        return log_sync_run_error(sync_run) unless sync_run.may_query?

        sync_run.query!

        result = fetch_records(sync_run)

        process_result(result, sync_run)

        heartbeat(activity, sync_run, nil)

        sync_run.queue!
      end

      private

      def fetch_records(sync_run)
        source_client = setup_source_client(sync_run.sync)
        result = source_client.read(sync_run.sync.to_protocol)
        if result.nil? || !result.is_a?(Array)
          Rails.logger.error({
            error_message: "Expected records in the result query = #{sync_run.sync.to_protocol.model.query}.
              Result = #{result.inspect}",
            sync_run_id: sync_run.id,
            sync_id: sync_run.sync_id,
            stack_trace: nil
          }.to_s)
          raise "Expected record in the result, but got #{result.inspect}"
        end
        result
      end

      # TODO: Using markdown (a large text) as a primary key has performance implications.
      # We should use a smaller identifier like markdown_hash instead
      def process_result(result, sync_run)
        skipped_rows = 0
        model = sync_run.sync.model
        result.each do |res|
          record = res.record
          fingerprint = generate_fingerprint(record.data)
          sync_record = process_record(record, sync_run, model)
          skipped_rows += update_or_create_sync_record(sync_record, record, sync_run, fingerprint) ? 0 : 1
        end
        sync_run.update(
          current_offset: 0,
          total_query_rows: result.size,
          skipped_rows:
        )
      end
    end
  end
end
