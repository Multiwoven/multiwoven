# frozen_string_literal: true

module ReverseEtl
  module Loaders
    class Standard < Base
      THREAD_COUNT = (ENV["SYNC_LOADER_THREAD_POOL_SIZE"] || "5").to_i
      def write(sync_run_id, activity)
        sync_run = SyncRun.find(sync_run_id)
        sync = sync_run.sync
        sync_config = sync.to_protocol
        if sync_config.stream.batch_support
          process_batch_records(sync_run, sync, sync_config, activity)
        else
          process_individual_records(sync_run, sync, sync_config, activity)
        end
      end

      private

      def process_individual_records(sync_run, sync, sync_config, activity)
        transformer = Transformers::UserMapping.new
        client = sync.destination.connector_client.new

        sync_run.sync_records.pending.find_in_batches do |sync_records|
          # track sync record status
          successfull_sync_records = []
          failed_sync_records = []

          Parallel.each(sync_records, in_threads: THREAD_COUNT) do |sync_record|
            record = transformer.transform(sync, sync_record)
            report = client.write(sync_config, [record]).tracking

            if report.success.zero?
              failed_sync_records << sync_record.id
            else
              successfull_sync_records << sync_record.id
            end
          rescue StandardError => e
            Rails.logger(e)
          end
          heartbeat(activity)

          update_sync_records_status(sync_run, successfull_sync_records, failed_sync_records)
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
          report = client.write(sync_config, transformed_records).tracking
          heartbeat(activity)
          if report.success.zero?
            failed_sync_records.concat(sync_records.map { |record| record["id"] }.compact)
          else
            successfull_sync_records.concat(sync_records.map { |record| record["id"] }.compact)
          end
        rescue StandardError => e
          Rails.logger.error(e)
        end
        update_sync_records_status(sync_run, successfull_sync_records, failed_sync_records)
      end

      def update_sync_records_status(sync_run, successfull_sync_records, failed_sync_records)
        sync_run.sync_records.where(id: successfull_sync_records).update_all(status: "success") # rubocop:disable Rails/SkipsModelValidations
        sync_run.sync_records.where(id: failed_sync_records).update_all(status: "failed") # rubocop:disable Rails/SkipsModelValidations
      end

      def heartbeat(activity)
        activity.heartbeat
        raise StandardError, "Cancel activity request received" if activity.cancel_requested
      end
    end
  end
end
