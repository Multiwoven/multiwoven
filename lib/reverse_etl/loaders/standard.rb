# frozen_string_literal: true

module ReverseEtl
  module Loaders
    class Standard < Base
      THREAD_COUNT = 10
      # TODO: write tests for this method
      def write(sync_run_id)
        sync_run = SyncRun.find(sync_run_id)
        sync = sync_run.sync
        sync_config = sync.to_protocol

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
          sync_run.sync_records.where(id: successfull_sync_records).update_all(status: "success") # rubocop:disable Rails/SkipsModelValidations
          sync_run.sync_records.where(id: failed_sync_records).update_all(status: "failed") # rubocop:disable Rails/SkipsModelValidations
        end
      end
    end
  end
end
