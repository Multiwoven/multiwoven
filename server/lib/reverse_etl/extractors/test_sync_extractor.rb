# frozen_string_literal: true

module ReverseEtl
  module Extractors
    class TestSyncExtractor < Base
      def read(sync_run_id, activity)
        sync_run = SyncRun.find(sync_run_id)
        return log_sync_run_error(sync_run) unless sync_run.may_query?

        sync_run.query!

        result = fetch_records(sync_run)

        process_result(result, sync_run)

        heartbeat(activity, sync_run)

        # change state querying to queued
        sync_run.queue!
      end

      private

      def fetch_records(sync_run)
        source_client = setup_source_client(sync_run.sync)
        modified_sync_config = build_random_record_query_sync_config(sync_run.sync.to_protocol)
        result = source_client.read(modified_sync_config)
        if result.nil? || !result.is_a?(Array) || result.count != 1
          Rails.logger.error({
            error_message: "Expected exactly one record in the result query = #{modified_sync_config.model.query}.
              Result = #{result.inspect}",
            sync_run_id: sync_run.id,
            sync_id: sync_run.sync_id,
            stack_trace: nil
          }.to_s)
          raise "Expected exactly one record in the result, but got #{result.inspect}"
        end
        result
      end

      def build_random_record_query_sync_config(sync_config)
        random_query = ReverseEtl::Utils::RandomQueryBuilder.build_random_record_query(sync_config)
        new_model = build_new_model(sync_config.model, random_query)

        modified_sync_config = Multiwoven::Integrations::Protocol::SyncConfig.new(
          model: new_model.to_protocol,
          source: sync_config.source,
          destination: sync_config.destination,
          stream: sync_config.stream,
          sync_mode: sync_config.sync_mode,
          destination_sync_mode: sync_config.destination_sync_mode,
          cursor_field: sync_config.cursor_field,
          current_cursor_field: sync_config.current_cursor_field,
          sync_id: sync_config.sync_id
        )
        modified_sync_config.offset = 0
        modified_sync_config.limit = 1
        modified_sync_config.sync_run_id = sync_config.sync_run_id
        modified_sync_config
      end

      def build_new_model(existing_model, new_query)
        Model.new(
          name: existing_model.name,
          query: new_query,
          query_type: existing_model.query_type,
          primary_key: existing_model.primary_key
        )
      end

      def process_result(result, sync_run)
        record = result.first.record
        fingerprint = generate_fingerprint(record.data)
        model = sync_run.sync.model
        sync_record = process_record(record, sync_run, model)
        skipped_rows = update_or_create_sync_record(sync_record, record, sync_run, fingerprint) ? 0 : 1
        sync_run.update(current_offset: 0, total_query_rows: 1, skipped_rows:)
      end

      def heartbeat(activity, sync_run)
        response = activity.heartbeat
        return unless response.cancel_requested

        sync_run.failed!
        sync_run.sync_records.delete_all
        Rails.logger.error({
          error_message: "Cancel activity request received",
          sync_run_id: sync_run.id,
          sync_id: sync_run.sync_id,
          stack_trace: nil
        }.to_s)
        raise StandardError, "Cancel activity request received"
      end
    end
  end
end
