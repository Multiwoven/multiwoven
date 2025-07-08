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

        heartbeat(activity, sync_run)

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

      def process_result(result, sync_run)
        skipped_rows = 0
        total_query_rows = 0
        model = sync_run.sync.model
        chunk_config = { chunk_size: 1000, chunk_overlap: 200 }
        result.each do |res|
          record = res.record
          chunk_records = process_file_content(chunk_config, record.data[:markdown])
          chunk_records.map do |chunk_record|
            new_record = build_record(chunk_record, record.data[:metadata])
            fingerprint = generate_fingerprint(new_record.data)
            sync_record = process_record(new_record, sync_run, model)
            total_query_rows += 1
            skipped_rows += update_or_create_sync_record(sync_record, new_record, sync_run, fingerprint) ? 0 : 1
          end
        end
        sync_run.update(
          current_offset: 0,
          total_query_rows:,
          skipped_rows:
        )
      end

      def process_file_content(chunk_config, markdown_content)
        ReverseEtl::Processors::Text::ChunkProcessor.new.process(
          chunk_config,
          markdown_content,
          {}
        )
      rescue StandardError => e
        raise ChunkProcessingError, "Failed to process file content: #{e.message}"
      end

      def build_record(message, metadata)
        record_data = message.with_indifferent_access
        # Used for structured purposes when passing data to process_record
        Multiwoven::Integrations::Protocol::RecordMessage.new(
          data: {
            markdown: record_data["text"],
            markdown_hash: record_data["element_id"],
            metadata:,
            url: JSON.parse(metadata)["url"]
          },
          emitted_at: Time.zone.now.to_i
        )
      end
    end
  end
end
