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
            begin
              # Check if record has all required fields before transformation
              if missing_fields = missing_required_fields(sync_record, sync_config)
                reason = "Missing required fields: #{missing_fields.join(', ')}"
                Rails.logger.warn("LOADER: Skipping record id=#{sync_record.id}, reason=#{reason}")
                skipped_records << { id: sync_record.id, reason: reason }
                sync_record.update(status: 'failed', logs: { request: reason, level: "error" })
                next
              end
              
              transformer = Transformers::UserMapping.new
              record = transformer.transform(sync, sync_record)
              
              Rails.logger.info("LOADER: Processing record id=#{sync_record.id} for sync_id=#{sync.id} sync_run_id=#{sync_run.id}")
              report = handle_response(client.write(sync_config, [record], sync_record.action), sync_run)
              
              # Check if the record was processed successfully or has detailed error logs
              update_sync_record_logs_and_status(report, sync_record)
              
              # Track failed records with reasons from the report
              if sync_record.status == 'failed'
                error_details = get_sync_records_logs(report) || { reason: "Unknown failure reason" }
                failed_records << { id: sync_record.id, reason: error_details }
                Rails.logger.error("LOADER: Record id=#{sync_record.id} failed: #{error_details.to_json}")
              end
            rescue Activities::LoaderActivity::FullRefreshFailed
              raise
            rescue StandardError => e
              error_message = e.message
              stack_trace = Rails.backtrace_cleaner.clean(e.backtrace)
              
              Rails.logger.error({
                error_message: error_message,
                sync_run_id: sync_run.id,
                sync_id: sync_run.sync_id,
                record_id: sync_record.id,
                stack_trace: stack_trace
              }.to_json)
              
              # Update the record status and logs
              sync_record.update(status: 'failed', logs: { 
                error_message: error_message,
                stack_trace: stack_trace.first(5)
              })
              
              failed_records << { id: sync_record.id, reason: error_message }
            end
          end

          heartbeat(activity, sync_run)
        end
        
        # Log summary of skipped and failed records
        if skipped_records.any?
          Rails.logger.warn("LOADER: Skipped #{skipped_records.size} records for sync_id=#{sync.id}, sync_run_id=#{sync_run.id}")
          Rails.logger.warn("LOADER: Skipped records summary: #{skipped_records.group_by { |r| r[:reason] }.transform_values(&:count)}")
        end
        
        if failed_records.any?
          Rails.logger.error("LOADER: Failed #{failed_records.size} records for sync_id=#{sync.id}, sync_run_id=#{sync_run.id}")
          # Group failures by reason and count them
          failure_summary = failed_records.group_by { |r| r[:reason].to_s.truncate(100) }.transform_values(&:count)
          Rails.logger.error("LOADER: Failed records summary: #{failure_summary}")
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
          begin
            batch_id = SecureRandom.uuid[0..7] # Generate a short ID to track this batch in logs
            
            Rails.logger.info("LOADER: Processing batch #{batch_id} with #{sync_records.size} records for sync_id=#{sync.id}")
            
            # Filter out records missing required fields
            valid_records = []
            sync_records.each do |sync_record|
              if missing_fields = missing_required_fields(sync_record, sync_config)
                reason = "Missing required fields: #{missing_fields.join(', ')}"
                Rails.logger.warn("LOADER: Skipping record id=#{sync_record.id} in batch #{batch_id}, reason=#{reason}")
                skipped_sync_records << { id: sync_record.id, reason: reason }
                sync_record.update(status: 'failed', logs: { request: reason, level: "error" })
              else
                valid_records << sync_record
              end
            end
            
            # Skip empty batches
            if valid_records.empty?
              Rails.logger.warn("LOADER: Batch #{batch_id} has no valid records after filtering, skipping")
              next
            end
            
            transformed_records = valid_records.map { |sync_record| transformer.transform(sync, sync_record) }
            
            Rails.logger.info("LOADER: Sending batch #{batch_id} with #{transformed_records.size} records to destination")
            report = handle_response(client.write(sync_config, transformed_records), sync_run)
            
            # Extract detailed error information from the report if available
            error_details = get_batch_error_details(report)
            
            if report.tracking.success.zero?
              Rails.logger.error("LOADER: Batch #{batch_id} failed completely: #{error_details}")
              failed_sync_records.concat(valid_records.map { |record| { id: record.id, reason: error_details } })
            elsif report.tracking.success < transformed_records.size
              # Some records succeeded, some failed
              success_count = report.tracking.success
              fail_count = report.tracking.failed
              
              Rails.logger.warn("LOADER: Batch #{batch_id} partially succeeded: #{success_count} success, #{fail_count} failed")
              
              # Since we don't know which specific records failed, we'll mark the first success_count as successful
              # and the rest as failed
              successfull_sync_records.concat(valid_records[0...success_count].map { |record| record.id })
              failed_sync_records.concat(valid_records[success_count..-1].map { |record| { id: record.id, reason: error_details } })
            else
              Rails.logger.info("LOADER: Batch #{batch_id} succeeded completely with #{transformed_records.size} records")
              successfull_sync_records.concat(valid_records.map { |record| record.id })
            end
          rescue Activities::LoaderActivity::FullRefreshFailed
            raise
          rescue StandardError => e
            error_message = "#{e.class}: #{e.message}"
            stack_trace = Rails.backtrace_cleaner.clean(e.backtrace)
            
            Rails.logger.error({
              error_message: error_message,
              sync_run_id: sync_run.id,
              sync_id: sync_run.sync_id,
              batch_size: sync_records.size,
              stack_trace: stack_trace
            }.to_json)
            
            # Mark all records in the batch as failed
            failed_sync_records.concat(sync_records.map { |record| { id: record.id, reason: error_message } })
          end
        end
        
        # Update record statuses with their respective reasons
        update_sync_records_status(sync_run, successfull_sync_records, failed_sync_records.map { |r| r[:id] })
        
        # Update logs for failed records with their specific reasons
        failed_sync_records.each do |record_info|
          sync_record = sync_run.sync_records.find_by(id: record_info[:id])
          if sync_record
            sync_record.update(logs: { request: record_info[:reason], level: "error" })
          end
        end
        

        
        heartbeat(activity, sync_run)
      end

      def handle_response(report, sync_run)
        is_multiwoven_tracking_message = report.is_a?(Multiwoven::Integrations::Protocol::MultiwovenMessage) &&
                                         report.type == "tracking" &&
                                         report.tracking.is_a?(Multiwoven::Integrations::Protocol::TrackingMessage)
        raise_non_retryable_error(report, sync_run) unless is_multiwoven_tracking_message
        
        # Log summary of success and failures from the report
        if report.tracking.failed > 0
          Rails.logger.error("SYNC_ERROR: Report shows #{report.tracking.failed} failed records out of #{report.tracking.success + report.tracking.failed} total")
          
          # Log detailed error information if available
          if report.tracking.respond_to?(:logs) && report.tracking.logs&.first&.message.present?
            begin
              error_details = JSON.parse(report.tracking.logs.first.message)
              Rails.logger.error("SYNC_ERROR: Details: #{error_details}")
            rescue JSON::ParserError
              # If we can't parse the error details, just log the raw message
              Rails.logger.error("SYNC_ERROR: Raw error: #{report.tracking.logs.first.message}")
            end
          end
        end
        
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
      
      def get_batch_error_details(report)
        if report.tracking.respond_to?(:logs) && report.tracking.logs&.first&.message.present?
          begin
            error_data = JSON.parse(report.tracking.logs.first.message)
            if error_data.is_a?(Hash) && error_data['errors'].is_a?(Array) && error_data['errors'].any?
              # Group errors by type and message for a summary
              error_groups = error_data['errors'].group_by { |e| [e['error_type'], e['error_message']] }
              return error_groups.map { |(type, msg), errors| "#{type}: #{msg} (#{errors.size} records)" }.join("; ")
            end
            return error_data.to_s
          rescue JSON::ParserError
            return report.tracking.logs.first.message.to_s
          end
        end
        "Unknown error"
      end
      
      def missing_required_fields(sync_record, sync_config)
        # Get required fields from the schema
        required_fields = []
        
        # For Facebook Custom Audience, we need at least one identifier
        if sync_config.destination.name == 'FacebookCustomAudience'
          identifiers = ['EMAIL', 'PHONE', 'EXTERN_ID', 'MADID', 'PAGEUID']
          record_data = sync_record.record
          
          # Check if at least one identifier is present
          has_identifier = identifiers.any? { |id| record_data[id].present? }
          return ['at least one identifier (EMAIL, PHONE, EXTERN_ID, MADID, PAGEUID)'] unless has_identifier
          
          # Check email format if present
          if record_data['EMAIL'].present? && !valid_email?(record_data['EMAIL'])
            return ['valid EMAIL format']
          end
          
          # Check phone format if present
          if record_data['PHONE'].present? && !valid_phone?(record_data['PHONE'])
            return ['valid PHONE format']
          end
        end
        
        # No missing required fields
        nil
      end
      
      def valid_email?(email)
        email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
      end
      
      def valid_phone?(phone)
        # Basic phone validation - adjust as needed
        phone.to_s.gsub(/[^0-9]/, '').length >= 10
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
