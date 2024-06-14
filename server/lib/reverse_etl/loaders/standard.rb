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

        if sync_config.stream.batch_support
          process_batch_records(sync_run, sync, sync_config, activity)
        else
          process_individual_records(sync_run, sync, sync_config, activity)
        end
      end

      private

      def process_individual_records(sync_run, sync, sync_config, activity)
        client = sync.destination.connector_client.new

        sync_run.sync_records.pending.find_in_batches do |sync_records|
          # track sync record status
          successfull_sync_records = []
          failed_sync_records = []

          # concurrent request rate limit
          concurrency = sync_config.stream.request_rate_concurrency || THREAD_COUNT

          Parallel.each(sync_records, in_threads: concurrency) do |sync_record|
            transformer = Transformers::UserMapping.new
            record = transformer.transform(sync, sync_record)
            Rails.logger.info "sync_id = #{sync.id} sync_run_id = #{sync_run.id} sync_record = #{record}"
            report = handle_response(client.write(sync_config, [record]), sync_run)
            if report.tracking.success.zero?
              failed_sync_records << sync_record.id
            else
              successfull_sync_records << sync_record.id
            end
          rescue Activities::LoaderActivity::FullRefreshFailed
            raise
          rescue StandardError => e
            Utils::ExceptionReporter.report(e, {
                                              sync_run_id: sync_run.id,
                                              sync_id: sync.id
                                            })
            Rails.logger(e)
          end

          update_sync_records_status(sync_run, successfull_sync_records, failed_sync_records)

          heartbeat(activity)
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
          heartbeat(activity)
          if report.tracking.success.zero?
            failed_sync_records.concat(sync_records.map { |record| record["id"] }.compact)
          else
            successfull_sync_records.concat(sync_records.map { |record| record["id"] }.compact)
          end
        rescue Activities::LoaderActivity::FullRefreshFailed
          raise
        rescue StandardError => e
          Utils::ExceptionReporter.report(e, {
                                            sync_run_id: sync_run.id
                                          })
          Rails.logger.error({
            error_message: e.message,
            sync_run_id: sync_run.id,
            stack_trace: Rails.backtrace_cleaner.clean(e.backtrace)
          }.to_s)
        end
        update_sync_records_status(sync_run, successfull_sync_records, failed_sync_records)
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

      def update_sync_records_status(sync_run, successfull_sync_records, failed_sync_records)
        sync_run.sync_records.where(id: successfull_sync_records).update_all(status: "success") # rubocop:disable Rails/SkipsModelValidations
        sync_run.sync_records.where(id: failed_sync_records).update_all(status: "failed") # rubocop:disable Rails/SkipsModelValidations
      end

      def heartbeat(activity)
        activity.heartbeat
        raise StandardError, "Cancel activity request received" if activity.cancel_requested
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
