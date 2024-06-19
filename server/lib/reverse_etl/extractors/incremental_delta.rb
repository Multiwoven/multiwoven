# frozen_string_literal: true

module ReverseEtl
  module Extractors
    class IncrementalDelta < Base
      # TODO: Make it as class method
      def read(sync_run_id, activity)
        total_query_rows = 0
        skipped_rows = 0

        sync_run = SyncRun.find(sync_run_id)

        return log_sync_run_error(sync_run) unless sync_run.may_query?

        sync_run.query!

        source_client = setup_source_client(sync_run.sync)

        batch_query_params = batch_params(source_client, sync_run)
        model = sync_run.sync.model

        ReverseEtl::Utils::BatchQuery.execute_in_batches(batch_query_params) do |records,
          current_offset, last_cursor_field_value|

          total_query_rows += records.count
          skipped_rows += process_records(records, sync_run, model)
          heartbeat(activity)
          sync_run.update(current_offset:, total_query_rows:, skipped_rows:)
          sync_run.sync.update(current_cursor_field: last_cursor_field_value)
        end
        # change state querying to queued
        sync_run.queue!
      end

      private

      # TODO: refactor this method
      def process_records(records, sync_run, model)
        Parallel.map(records, in_threads: THREAD_COUNT) do |message|
          record = message.record
          fingerprint = generate_fingerprint(record.data)
          sync_record = process_record(record, sync_run, model)
          update_or_create_sync_record(sync_record, record, sync_run, fingerprint) ? 0 : 1
        end.sum
      end

      def process_record(record, sync_run, model)
        primary_key = record.data.with_indifferent_access[model.primary_key]
        raise StandardError, "Primary key cannot be blank" if primary_key.blank?

        find_or_initialize_sync_record(sync_run, primary_key)
      rescue StandardError => e
        # ::Utils::ExceptionReporter.report(e, {
        #                                     sync_run_id: sync_run.id
        #                                   })
        Rails.logger.error({
          error_message: e.message,
          sync_run_id: sync_run.id,
          sync_id: sync_run.sync_id,
          stack_trace: Rails.backtrace_cleaner.clean(e.backtrace)
        }.to_s)
        nil
      end

      def find_or_initialize_sync_record(sync_run, primary_key)
        # In parallel processing, we encountered a scenario where one thread was processing and had not yet persisted
        # to the database, while another thread attempted to create a new record with the same primary key
        # for a synchronization. To prevent this, we used database constraints. However,
        # in future cases where a synchronization contains both create and update operations,
        # there might be a risk of losing either the update or the create due to these concurrent operations.
        # we can use  ActiveRecord::Base.transaction  to prevent such scenarios
        SyncRecord.find_by(sync_id: sync_run.sync_id, primary_key:) ||
          sync_run.sync_records.new(sync_id: sync_run.sync_id, primary_key:, created_at: DateTime.current)
      end

      def new_record?(sync_record, fingerprint)
        sync_record.new_record? || sync_record.fingerprint != fingerprint
      end

      def action(sync_record)
        sync_record.new_record? ? :destination_insert : :destination_update
      end

      def update_or_create_sync_record(sync_record, record, sync_run, fingerprint)
        unless sync_record && new_record?(sync_record, fingerprint)
          primary_key = record.data.with_indifferent_access[sync_run.sync.model.primary_key]
          Rails.logger.info({
            message: "Skipping sync record",
            primary_key:,
            sync_id: sync_run.sync_id,
            sync_run_id: sync_run.id,
            sync_record_id: sync_record&.id
          }.to_s)

          return false
        end
        sync_record.assign_attributes(
          sync_run_id: sync_run.id,
          action: action(sync_record),
          fingerprint:,
          record: record.data,
          status: "pending"
        )
        sync_record.save!
      end
    end
  end
end
