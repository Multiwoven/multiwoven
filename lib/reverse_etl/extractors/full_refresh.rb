# frozen_string_literal: true

module ReverseEtl
  module Extractors
    class FullRefresh < Base
      def read(sync_run_id, activity)
        total_query_rows = 0
        sync_run = SyncRun.find(sync_run_id)

        return log_sync_run_error(sync_run) unless sync_run.may_query?

        sync_run.query!

        source_client = setup_source_client(sync_run.sync)
        model = sync_run.sync.model
        batch_query_params = batch_params(source_client, sync_run)

        # TODO: Need to move on flush/clean temporal activity after Loader activity
        flush_records(sync_run)

        ReverseEtl::Utils::BatchQuery.execute_in_batches(batch_query_params) do |records, current_offset|
          total_query_rows += records.count
          process_records(records, sync_run, model)
          heartbeat(activity)
          sync_run.update(current_offset:, total_query_rows:)
        end

        # change state querying to queued
        sync_run.queue!
      end

      private

      def flush_records(sync_run)
        SyncRecord.where(sync_id: sync_run.sync_id).delete_all
      end

      def process_records(records, sync_run, model)
        sync_records_to_save = build_sync_records_in_parallel(records, sync_run, model)
        return if sync_records_to_save.empty?

        result = SyncRecord.insert_all(sync_records_to_save, returning: %w[primary_key]) # rubocop:disable Rails/SkipsModelValidations
        return if records.count == sync_records_to_save.count && sync_records_to_save.count == result.rows.size

        log_mismatch_error(records, sync_records_to_save, result.rows.flatten,
                           sync_run)
      rescue StandardError => e
        log_error("#{e.message}. Sync ID: #{sync_run.sync_id}, Sync Run ID: #{sync_run.id}.")
      end

      def build_sync_records_in_parallel(records, sync_run, model)
        # TODO: Evaluate the necessity of parallel processing and benchmark the scenarios
        Parallel.map(records, in_threads: THREAD_COUNT) do |message|
          build_sync_record(message, sync_run, model)
        end.compact # Ensure to remove nil items potentially added due to primary key check or errors
      end

      def build_sync_record(message, sync_run, model)
        record_data = message.record.data.with_indifferent_access
        primary_key_value = record_data[model.primary_key]

        if primary_key_value.nil?
          error_message = "Primary key value is missing for sync_id: #{sync_run.sync_id}, sync_run_id: #{sync_run.id}.
            Record data: #{record_data.to_json}"
          log_error(error_message)
          return nil
        end
        {
          sync_id: sync_run.sync_id,
          primary_key: primary_key_value,
          created_at: DateTime.current,
          sync_run_id: sync_run.id,
          action: :destination_insert,
          fingerprint: generate_fingerprint(record_data),
          record: record_data
        }
      rescue StandardError => e
        error_message = "#{e.message}. Sync ID: #{sync_run.sync_id}, Sync Run ID: #{sync_run.id}.
          Record data: #{record_data.to_json}"
        log_error(error_message)
        nil
      end

      def log_mismatch_error(records, sync_records_to_save, valid_primary_keys, sync_run)
        error_message = "Mismatch in record count. Expected to insert #{records.count} records.
        Sync records to save after process records  #{sync_records_to_save.count} records.
        Successfully inserted #{valid_primary_keys.count} records.
        Sync ID: #{sync_run.sync_id}, Sync Run ID: #{sync_run.id}."
        log_error(error_message)
      end

      def log_error(error_message)
        Temporal.logger.error(
          error_message:
        )
      end
    end
  end
end
