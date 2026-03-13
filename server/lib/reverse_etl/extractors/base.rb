# frozen_string_literal: true

module ReverseEtl
  module Extractors
    # rubocop:disable Metrics/ClassLength
    class Base
      DEFAULT_OFFSET = 0
      DEFAULT_BATCH_SIZE = (ENV["SYNC_EXTRACTOR_BATCH_SIZE"] || "10000").to_i
      DEFAULT_LIMIT = (ENV["SYNC_EXTRACTOR_BATCH_SIZE"] || "10000").to_i
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
        if sync_config.increment_strategy_config.present?
          build_http_params(client, sync_run, sync_config)
        else
          {
            offset: sync_run.current_offset || DEFAULT_OFFSET,
            limit: DEFAULT_LIMIT,
            batch_size: DEFAULT_BATCH_SIZE,
            sync_config:,
            client:
          }
        end
      end

      def build_http_params(client, sync_run, sync_config)
        increment_strategy_config = sync_config.increment_strategy_config
        if increment_strategy_config.increment_strategy == "page"
          {
            increment_strategy_config.limit_variable => increment_strategy_config.limit,
            increment_strategy_config.offset_variable => offset_value(sync_run, increment_strategy_config),
            batch_size: 1,
            sync_config:,
            client:
          }
        elsif increment_strategy_config.increment_strategy == "offset"
          {
            limit: increment_strategy_config.limit || DEFAULT_LIMIT,
            offset: increment_strategy_config.offset || DEFAULT_OFFSET,
            batch_size: increment_strategy_config.limit || DEFAULT_BATCH_SIZE,
            sync_config:,
            client:
          }
        end
      end

      def offset_value(sync_run, increment_strategy_config)
        if sync_run.current_offset.nil? || sync_run.current_offset.zero?
          increment_strategy_config.offset
        else
          sync_run.current_offset
        end
      end

      def log_sync_run_error(sync_run)
        Rails.logger.error({
          error_message: "SyncRun cannot querying from its current state: #{sync_run.status}",
          sync_run_id: sync_run.id,
          stack_trace: nil
        }.to_s)
      end

      def log_skip_sync_run(sync_record, record, sync_run, error = nil)
        primary_key = record.data.with_indifferent_access[sync_run.sync.model.primary_key]
        message = error ? error.message : "Skipping sync record"

        Rails.logger.info({
          message:,
          primary_key:,
          sync_id: sync_run.sync_id,
          sync_run_id: sync_run.id,
          sync_record_id: sync_record&.id
        }.to_s)
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
          SyncRecord.new(sync_id: sync_run.sync_id, sync_run_id: sync_run.id,
                         primary_key:, created_at: DateTime.current)
      end

      def batch_find_sync_records(sync_run, records, model)
        primary_keys = records.filter_map do |message|
          pk = message.record.data.with_indifferent_access[model.primary_key]
          pk.presence&.to_s
        end

        return {} if primary_keys.empty?

        SyncRecord.where(sync_id: sync_run.sync_id, primary_key: primary_keys)
                  .index_by { |r| r.primary_key.to_s }
      end

      def build_upsert_records(records, sync_run, model)
        sync_records_cache = batch_find_sync_records(sync_run, records, model)
        upsert_by_pk = {}
        skipped_count = 0

        records.each do |message|
          record = message.record
          primary_key = record.data.with_indifferent_access[model.primary_key]

          if primary_key.blank?
            Rails.logger.error({
              error_message: "Primary key cannot be blank",
              sync_run_id: sync_run.id,
              sync_id: sync_run.sync_id,
              stack_trace: nil
            }.to_s)
            skipped_count += 1
            next
          end

          pk_str = primary_key.to_s
          fingerprint = generate_fingerprint(record.data)
          existing = sync_records_cache[pk_str]

          if existing && existing.fingerprint == fingerprint
            skipped_count += 1
            next
          end

          skipped_count += 1 if upsert_by_pk.key?(pk_str)

          upsert_by_pk[pk_str] = {
            sync_id: sync_run.sync_id,
            sync_run_id: sync_run.id,
            primary_key:,
            action: existing ? :destination_update : :destination_insert,
            fingerprint:,
            record: record.data,
            status: :pending,
            created_at: DateTime.current,
            updated_at: DateTime.current
          }
        end

        [upsert_by_pk.values, skipped_count]
      end

      def batch_upsert_sync_records(records_to_upsert)
        return if records_to_upsert.empty?

        SyncRecord.upsert_all( # rubocop:disable Rails/SkipsModelValidations
          records_to_upsert,
          unique_by: :index_sync_records_on_sync_id_and_primary_key,
          update_only: %i[sync_run_id action fingerprint record status]
        )
      rescue ActiveRecord::RecordNotUnique => e
        Rails.logger.warn({
          error_message: "Batch upsert hit unique constraint, falling back to individual upsert",
          details: e.message
        }.to_s)
        records_to_upsert.each do |attrs|
          SyncRecord.upsert( # rubocop:disable Rails/SkipsModelValidations
            attrs,
            unique_by: :index_sync_records_on_sync_id_and_primary_key,
            update_only: %i[sync_run_id action fingerprint record status]
          )
        rescue StandardError => individual_error
          Rails.logger.error({
            error_message: "Individual upsert failed for primary_key=#{attrs[:primary_key]}",
            details: individual_error.message
          }.to_s)
        end
      end

      def new_record?(sync_record, fingerprint)
        sync_record.new_record? || sync_record.fingerprint != fingerprint
      end

      def action(sync_record)
        sync_record.new_record? ? :destination_insert : :destination_update
      end

      def update_or_create_sync_record(sync_record, record, sync_run, fingerprint)
        begin
          unless sync_record && new_record?(sync_record, fingerprint)
            log_skip_sync_run(sync_record, record, sync_run)

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
      rescue StandardError => e
        log_skip_sync_run(sync_record, record, sync_run, e)
        false
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
