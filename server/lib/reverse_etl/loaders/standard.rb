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
        connector_name = sync_config.destination.name
        
        # Track skipped records with reasons
        skipped_records = []
        failed_records = []
        
        Rails.logger.info("LOADER: Starting individual record processing for sync_id=#{sync.id}, sync_run_id=#{sync_run.id}, destination=#{connector_name}")

        sync_run.sync_records.pending.find_in_batches do |sync_records|
          # concurrent request rate limit
          concurrency = sync_config.stream.request_rate_concurrency || THREAD_COUNT
          
          Rails.logger.info("LOADER: Processing batch of #{sync_records.size} records with concurrency=#{concurrency}")

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
        connector_name = sync_config.destination.name

        # track sync record status with detailed reasons
        successfull_sync_records = []
        failed_sync_records = []
        skipped_sync_records = []
        
        Rails.logger.info("LOADER: Starting batch processing for sync_id=#{sync.id}, sync_run_id=#{sync_run.id}, destination=#{connector_name}, batch_size=#{batch_size}")

        Parallel.each(sync_run.sync_records.pending.find_in_batches(batch_size:),
                      in_threads: THREAD_COUNT) do |sync_records|
            transformed_records = sync_records.map { |sync_record| transformer.transform(sync, sync_record) }
            report = handle_response(client.write(sync_config, transformed_records), sync_run)
            if report.tracking.success.zero?
              failed_sync_records.concat(sync_records.map { |record| record["id"] }.compact)
            else
              successfull_sync_records.concat(sync_records.map { |record| record["id"] }.compact)
            end
          rescue Activities::LoaderActivity::FullRefreshFailed
            raise
          rescue StandardError
            # Utils::ExceptionReporter.report(e, {
            #                                   sync_run_id: sync_run.id
            #                                 })
          end
        update_sync_records_status(sync_run, successfull_sync_records, failed_sync_records)
        heartbeat(activity, sync_run)
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
        error_message = "Full refresh failed type:#{report.control.type} status: #{report.control.status}"
        Rails.logger.error({
          error_message: error_message,
          sync_run_id: sync_run.id,
          stack_trace: nil
        }.to_s)
        Rails.logger.error("SYNC_FATAL: #{error_message} for sync_run_id=#{sync_run.id}")
        raise Activities::LoaderActivity::FullRefreshFailed, "Full refresh failed (non-retryable)"
      end

      def update_sync_record_logs_and_status(report, sync_record)
        status = report.tracking.success.zero? ? "failed" : "success"
        logs = get_sync_records_logs(report)
        
        # Log failure reasons when a record fails
        if status == "failed" && logs.present?
          Rails.logger.error("SYNC_ERROR: Record #{sync_record.id} failed: #{logs.to_json}")
        end
        
        sync_record.update(logs: logs, status:)
      end

      def get_sync_records_logs(report)
        return unless report.tracking.respond_to?(:logs) && report.tracking.logs&.first&.message.present?

        begin
          JSON.parse(report.tracking.logs.first.message)
        rescue JSON::ParserError => e
          Rails.logger.error("LOADER: Failed to parse logs JSON: #{e.message}")
          { error: "Failed to parse error details: #{report.tracking.logs.first.message}" }
        end
      end

      def update_sync_records_status(sync_run, successfull_sync_records, failed_sync_records)
        # Log summary of success and failures
        if failed_sync_records.any?
          Rails.logger.error("SYNC_ERROR: #{failed_sync_records.size} records failed in sync_run_id=#{sync_run.id}")
        end
        
        # Calculate skipped records (those that were neither successful nor failed)
        total_records = sync_run.sync_records.pending.count
        processed_records = successfull_sync_records.size + failed_sync_records.size
        skipped_records = total_records - processed_records
        
        if skipped_records > 0
          Rails.logger.warn("SYNC_WARN: #{skipped_records} records were skipped in sync_run_id=#{sync_run.id}")
        end
        
        sync_run.sync_records.where(id: successfull_sync_records).update_all(status: "success") # rubocop:disable Rails/SkipsModelValidations
        sync_run.sync_records.where(id: failed_sync_records).update_all(status: "failed") # rubocop:disable Rails/SkipsModelValidations
        
        # Update remaining pending records as skipped
        remaining_pending = sync_run.sync_records.pending
        if remaining_pending.any?
          remaining_pending.update_all(status: "failed", logs: { request: "Record was skipped during processing", level: "error" }) # rubocop:disable Rails/SkipsModelValidations
        end
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
