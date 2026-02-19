# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module AmazonS3
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        conn = create_connection(connection_config)
        conn.head_bucket(bucket: connection_config[:bucket_name])
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "AMAZONS3:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def write(sync_config, records, _action = "destination_insert")
        records_size = records.size
        log_message_array = []
        write_success = upload_csv_content(sync_config, records)
        write_failure = records_size - write_success
        log_message_array << log_request_response("info", @args, @response)
        tracking_message(write_success, write_failure, log_message_array)
      rescue StandardError => e
        handle_exception(e, {
                           context: "AMAZONS3:WRITE:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def create_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        s3_options = {
          region: connection_config[:region],
          access_key_id: connection_config[:access_key_id],
          secret_access_key: connection_config[:secret_access_key]
        }
        endpoint = connection_config[:endpoint].to_s.strip
        if endpoint.present?
          s3_options[:endpoint] = endpoint
          s3_options[:force_path_style] = connection_config[:path_style] == true
        end
        Aws::S3::Client.new(**s3_options)
      end

      def upload_csv_content(sync_config, records)
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        conn = create_connection(connection_config)
        file_name = generate_local_file_name(connection_config)
        csv_content = generate_csv_content(records)
        begin
          @args = ["create", connection_config[:bucket_name], "#{connection_config[:file_path]}#{file_name}", csv_content]
          @response = conn.put_object(
            bucket: connection_config[:bucket_name],
            key: "#{connection_config[:file_path]}#{file_name}",
            body: csv_content
          )
          write_success = records.size
        rescue StandardError => e
          handle_exception(e, {
                             context: "AMAZONS3:RECORD:WRITE:EXCEPTION",
                             type: "error",
                             sync_id: sync_config.sync_id,
                             sync_run_id: sync_config.sync_run_id
                           })
          write_success = 0
        end
        write_success
      end

      def generate_csv_content(records)
        CSV.generate do |csv|
          headers = records.first.keys
          csv << headers
          records.each { |record| csv << record.values_at(*headers) }
        end
      end

      def generate_local_file_name(connection_config)
        timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
        "#{connection_config[:file_name]}_#{timestamp}.#{connection_config[:format_type]}"
      end
    end
  end
end
