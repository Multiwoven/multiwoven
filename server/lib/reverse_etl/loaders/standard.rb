# frozen_string_literal: true

module ReverseEtl
  module Loaders
    class Standard < Base
      THREAD_COUNT = (ENV["SYNC_LOADER_THREAD_POOL_SIZE"] || "5").to_i
      def write(sync_run_id, activity)
        sync_run = SyncRun.find(sync_run_id)

        return log_error(sync_run) unless sync_run.may_progress?

        # change state queued to in_progress
        sync_run.progress!

        sync = sync_run.sync
        sync_config = sync.to_protocol
        sync_config.sync_run_id = sync_run.id.to_s

        if sync_config.stream.batch_support && !sync_run.test?
          process_batch_records(sync_run, sync, sync_config, activity)
        else
          process_individual_records(sync_run, sync, sync_config, activity)
        end
      end

      private

      def process_individual_records(sync_run, sync, sync_config, activity)
        client = sync.destination.connector_client.new

        sync_run.sync_records.pending.find_in_batches do |sync_records|
          # concurrent request rate limit
          concurrency = sync_config.stream.request_rate_concurrency || THREAD_COUNT

          Parallel.each(sync_records, in_threads: concurrency) do |sync_record|
            transformer = Transformers::UserMapping.new
            record = transformer.transform(sync, sync_record)
            Rails.logger.info "sync_id = #{sync.id} sync_run_id = #{sync_run.id} sync_record = #{record}"
            report = handle_response(client.write(sync_config, [record], sync_record.action), sync_run)
            update_sync_record_logs_and_status(report, sync_record)
          rescue Activities::LoaderActivity::FullRefreshFailed
            raise
          rescue StandardError => e
            # Utils::ExceptionReporter.report(e, {
            #                                   sync_run_id: sync_run.id,
            #                                   sync_id: sync.id
            #                                 })
            Rails.logger.error({
              error_message: e.message,
              sync_run_id: sync_run.id,
              sync_id: sync_run.sync_id,
              stack_trace: Rails.backtrace_cleaner.clean(e.backtrace)
            }.to_s)
          end

          heartbeat(activity, sync_run)
        end
      end

      def process_batch_records(sync_run, sync, sync_config, activity)
        transformer = Transformers::UserMapping.new
        client = sync.destination.connector_client.new
        batch_size = sync_config.stream.batch_size

        # track sync record status
        successfull_sync_records = []
        failed_sync_records = []

        Parallel.each(sync_run.sync_records.pending.find_in_batches(batch_size:),
                      in_threads: THREAD_COUNT) do |sync_records|
          transformed_records = sync_records.map { |sync_record| transformer.transform(sync, sync_record) }
          report = handle_response(client.write(sync_config, transformed_records), sync_run)
          if report.tracking.success.zero?
            failed_sync_records.concat(sync_records.map { |record| record["id"] }.compact)
          else
            successfull_sync_records.concat(sync_records.map { |record| record["id"] }.compact)
          end
<<<<<<< HEAD
        rescue Activities::LoaderActivity::FullRefreshFailed
          raise
        rescue StandardError
          # Utils::ExceptionReporter.report(e, {
          #                                   sync_run_id: sync_run.id
          #                                 })
        end
        update_sync_records_status(sync_run, successfull_sync_records, failed_sync_records)
        heartbeat(activity, sync_run)
=======
          update_sync_records_logs_and_status(sync_run, successful_sync_records, failed_sync_records)
          heartbeat(activity, sync_run)
        end
      end

      def process_single_batch(sync, sync_run, sync_config, sync_records, # rubocop:disable Metrics/ParameterLists
                               mutex, successful_sync_records, failed_sync_records)
        client = sync.destination.connector_client.new
        transformed_records, identifier_map, identifier_key = build_transformed_batch(sync, sync_records)
        report = handle_response(
          client.write(sync_config, transformed_records, "destination_insert", identifier_key), sync_run
        )
        record_batch_outcome(report, sync_records, identifier_map, identifier_key,
                             mutex, successful_sync_records, failed_sync_records)
      rescue Activities::LoaderActivity::FullRefreshFailed
        raise
      rescue ActiveRecord::RecordNotUnique => e
        mutex.synchronize do
          failed_sync_records.concat(build_failed_sync_records_from_sync_records(sync_records, e.message))
        end
        Rails.logger.warn("UniqueViolation in batch: sync_id=#{sync.id}, error=#{e.message}")
      rescue StandardError => e
        mutex.synchronize do
          failed_sync_records.concat(build_failed_sync_records_from_sync_records(sync_records, e.message))
        end
        Rails.logger.info(
          "Error in Batch Transformer, sync_id = #{sync.id}, " \
          "sync_run_id = #{sync_run.id}, error = #{e.message}"
        )
      ensure
        client&.close if client.respond_to?(:close)
      end

      def build_transformed_batch(sync, sync_records)
        transformer = Transformers::UserMapping.new
        record_identifier_key = SecureRandom.uuid
        sync_record_identifier_to_id = {}
        transformed_records = sync_records.map do |sr|
          record = transformer.transform(sync, sr)
          identifier = SecureRandom.uuid
          record[record_identifier_key] = identifier
          sync_record_identifier_to_id[identifier] = sr["id"]
          record
        end
        [transformed_records, sync_record_identifier_to_id, record_identifier_key]
      end

      def record_batch_outcome(report, _sync_records, # rubocop:disable Metrics/ParameterLists
                               identifier_map, identifier_key, mutex,
                               successful_sync_records, failed_sync_records)
        mutex.synchronize do
          successful_records, failed_records = build_failed_sync_records_from_report(identifier_map,
                                                                                     report, identifier_key)
          failed_sync_records.concat(failed_records)
          successful_sync_records.concat(successful_records)
        end
      end

      def build_failed_sync_records_from_report(sync_record_identifier_to_id, report,
                                                _record_identifier_key)
        successful_records = []
        failed_records = []
        (report.tracking.logs || []).each do |log|
          record_identifier = log.record_identifier
          next unless record_identifier.present? && sync_record_identifier_to_id[record_identifier].present?

          sync_record_id = sync_record_identifier_to_id[record_identifier]
          level = log.level
          message = nil
          begin
            message = JSON.parse(log.message)
          rescue JSON::ParserError => e
            Rails.logger.warn("Failed to parse log message for #{record_identifier}: #{e.message}")
            message = { "error" => log.message }
          end
          if level == "error"
            failed_records << { id: sync_record_id, status: "failed", logs: message }
          else
            successful_records << { id: sync_record_id, status: "success", logs: nil }
          end
        end
        [successful_records, failed_records]
      end

      def build_failed_sync_records_from_sync_records(sync_records, message)
        parsed_logs = begin
          JSON.parse(message)
        rescue JSON::ParserError
          { "error" => message }
        end
        sync_records.map { |sync_record| { id: sync_record["id"], status: "failed", logs: parsed_logs } }.compact
      end

      def log_sync_record_error(error, sync, sync_run, sync_record)
        Rails.logger.info("Error in Transformer, sync_id = #{sync.id}, " \
                          "sync_run_id = #{sync_run.id}, sync_record = #{sync_record.to_json} error = #{error.message}")
        Rails.logger.error({
          error_message: error.message,
          sync_run_id: sync_run.id,
          sync_id: sync_run.sync_id,
          stack_trace: Rails.backtrace_cleaner.clean(error.backtrace)
        }.to_s)
>>>>>>> e4bf26352 (fix(CE): implemented record_identifier mapper for batch support (#1886))
      end

      def handle_response(report, sync_run)
        is_multiwoven_tracking_message = report.is_a?(Multiwoven::Integrations::Protocol::MultiwovenMessage) &&
                                         report.type == "tracking" &&
                                         report.tracking.is_a?(Multiwoven::Integrations::Protocol::TrackingMessage)
        raise_non_retryable_error(report, sync_run) unless is_multiwoven_tracking_message
        report
      end

      def raise_non_retryable_error(report, sync_run)
        sync_run.failed!
        Rails.logger.error({
          error_message: "Full refresh failed type:#{report.control.type} status: #{report.control.status}",
          sync_run_id: sync_run.id,
          stack_trace: nil
        }.to_s)
        raise Activities::LoaderActivity::FullRefreshFailed, "Full refresh failed (non-retryable)"
      end

      def update_sync_record_logs_and_status(report, sync_record)
        status = report.tracking.success.zero? ? "failed" : "success"
        sync_record.update(logs: get_sync_records_logs(report), status:)
      end

      def get_sync_records_logs(report)
        return unless report.tracking.respond_to?(:logs) && report.tracking.logs&.first&.message.present?

        JSON.parse(report.tracking.logs.first.message)
      end

<<<<<<< HEAD
      def update_sync_records_status(sync_run, successfull_sync_records, failed_sync_records)
        sync_run.sync_records.where(id: successfull_sync_records).update_all(status: "success") # rubocop:disable Rails/SkipsModelValidations
        sync_run.sync_records.where(id: failed_sync_records).update_all(status: "failed") # rubocop:disable Rails/SkipsModelValidations
=======
      def update_sync_records_logs_and_status(sync_run, successful_sync_records, failed_sync_records)
        all_records = successful_sync_records.map { |r| { id: r[:id], status: "success", logs: r[:logs] } } +
                      failed_sync_records.map { |r| { id: r[:id], status: "failed", logs: r[:logs] } }

        return if all_records.empty?

        sync_run.sync_records.upsert_all( # rubocop:disable Rails/SkipsModelValidations
          all_records,
          unique_by: :id,
          update_only: %i[status logs]
        )
>>>>>>> e4bf26352 (fix(CE): implemented record_identifier mapper for batch support (#1886))
      end

      def heartbeat(activity, sync_run)
        response = activity.heartbeat
        return unless response.cancel_requested

        sync_run.failed!
        Rails.logger.error({
          error_message: "Cancel activity request received",
          sync_run_id: sync_run.id,
          sync_id: sync_run.sync_id,
          stack_trace: nil
        }.to_s)
        raise StandardError, "Cancel activity request received"
      end

      def log_error(sync_run)
        Rails.logger.error({
          error_message: "SyncRun cannot progress from its current state: #{sync_run.status}",
          sync_run_id: sync_run.id,
          stack_trace: nil
        }.to_s)
      end
    end
  end
end
