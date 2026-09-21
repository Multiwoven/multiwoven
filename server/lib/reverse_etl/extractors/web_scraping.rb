# frozen_string_literal: true

module ReverseEtl
  module Extractors
    class ChunkProcessingError < StandardError; end

    class WebScraping < Base
      include ::Utils::Constants
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

      def generate_chunk_config(sync_run)
        chunk_config = { chunk_size: 1000, chunk_overlap: 200 }
        mappings = sync_run.sync.configuration
        vector_mappings = mappings.select { |mapping| mapping["mapping_type"] == "vector" }
        unless vector_mappings.empty?
          # Get the vector config with the smallest token limit
          vector_config = vector_mappings
                          .select { |mapping| EMBEDDING_MODEL_TOKEN_LIMITS.key?(mapping["embedding_config"]["model"]) }
                          .min_by { |mapping| EMBEDDING_MODEL_TOKEN_LIMITS[mapping["embedding_config"]["model"]] }
          unless vector_config.nil?
            chunk_config = {
              model: vector_config["embedding_config"]["model"],
              provider: vector_config["embedding_config"]["mode"],
              chunk_size: EMBEDDING_MODEL_TOKEN_LIMITS[vector_config["embedding_config"]["model"]]
            }
          end
        end
        chunk_config
      end

      def generate_chunks(sync_run, markdown_content)
        chunk_config = generate_chunk_config(sync_run)
        ReverseEtl::Processors::Text::ChunkProcessor.new.process(chunk_config, markdown_content)
      rescue StandardError => e
        raise ReverseEtl::Extractors::ChunkProcessingError, "Failed to process file content: #{e.message}"
      end

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
<<<<<<< HEAD
          fingerprint = generate_fingerprint(record.data)
          sync_record = process_record(record, sync_run, model)
          skipped_rows += update_or_create_sync_record(sync_record, record, sync_run, fingerprint) ? 0 : 1
=======
          chunk_records = generate_chunks(sync_run, record.data[:markdown])
          chunk_records.map do |chunk_record|
            new_record = build_record(chunk_record, record.data[:metadata])
            fingerprint = generate_fingerprint(new_record.data)
            sync_record = process_record(new_record, sync_run, model)
            total_query_rows += 1
            skipped_rows += update_or_create_sync_record(sync_record, new_record, sync_run, fingerprint) ? 0 : 1
          end
>>>>>>> 667262992 (fix(CE): fix the issue for token limit solution for firecrawl (#1772))
        end
        sync_run.update(
          current_offset: 0,
          total_query_rows: result.size,
          skipped_rows:
        )
      end
<<<<<<< HEAD
=======

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
>>>>>>> 667262992 (fix(CE): fix the issue for token limit solution for firecrawl (#1772))
    end
  end
end
