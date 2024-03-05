# frozen_string_literal: true

module ReverseEtl
  module Extractors
    class IncrementalDelta < Base
      THREAD_COUNT = (ENV["SYNC_EXTRACTOR_THREAD_POOL_SIZE"] || "5").to_i

      # TODO: Make it as class method
      def read(sync_run_id, activity)
        total_query_rows = 0
        sync_run = SyncRun.find(sync_run_id)

        return log_error(sync_run) unless sync_run.may_query?

        sync_run.query!

        source_client = setup_source_client(sync_run.sync)

        batch_query_params = batch_params(source_client, sync_run)
        model = sync_run.sync.model

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

      def heartbeat(activity)
        activity.heartbeat
        raise StandardError, "Cancel activity request received" if activity.cancel_requested
      end

      def setup_source_client(sync)
        sync.source.connector_client.new
      end

      def process_records(records, sync_run, model)
        Parallel.each(records, in_threads: THREAD_COUNT) do |message|
          process_record(message, sync_run, model)
        end
      end

      def process_record(message, sync_run, model)
        record = message.record
        fingerprint = generate_fingerprint(record.data)
        primary_key = record.data.with_indifferent_access[model.primary_key]

        sync_record = find_or_initialize_sync_record(sync_run, primary_key)
        update_or_create_sync_record(sync_record, record, sync_run, fingerprint)
      rescue StandardError => e
        Temporal.logger.error(error_message: e.message,
                              sync_run_id: sync_run.id,
                              stack_trace: Rails.backtrace_cleaner.clean(e.backtrace))
      end

      def generate_fingerprint(data)
        Digest::SHA1.hexdigest(data.to_json)
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
        return unless new_record?(sync_record, fingerprint)

        sync_record.assign_attributes(
          sync_run_id: sync_run.id,
          action: action(sync_record),
          fingerprint:,
          record: record.data
        )
        sync_record.save!
      end

      def log_error(sync_run)
        Temporal.logger.error(
          eerror_message: "SyncRun cannot querying from its current state: #{sync_run.status}",
          sync_run_id: sync_run.id,
          stack_trace: nil
        )
      end
    end
  end
end
