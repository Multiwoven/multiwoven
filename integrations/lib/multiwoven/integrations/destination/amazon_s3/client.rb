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

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        conn = create_connection(connection_config)
        records = discover_columns_from_s3(conn, connection_config)
        grouped = group_by_table(records, connection_config[:file_name])
        catalog = Catalog.new(streams: create_streams(grouped))
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
        Aws::S3::Client.new(
          region: connection_config[:region],
          access_key_id: connection_config[:access_key_id],
          secret_access_key: connection_config[:secret_access_key]
        )
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

      def build_discover_prefix(connection_config)
        file_path = connection_config[:file_path].to_s.strip
        file_path = "#{file_path}/" if file_path.present? && file_path[-1] != "/"
        format_type = connection_config[:format_type].to_s.downcase
        "#{file_path}#{connection_config[:file_name]}.#{format_type}"
      end

      def discover_columns_from_s3(s3_client, connection_config)
        bucket = connection_config[:bucket_name]
        prefix = build_discover_prefix(connection_config)
        format_type = connection_config[:format_type].to_s.downcase

        response = s3_client.list_objects_v2(bucket: bucket, prefix: prefix, max_keys: 100)
        raise StandardError, "No files found in the bucket" if response.contents.empty?

        key = response.contents&.find { |obj| obj.key.end_with?(".#{format_type}") }&.key
        raise StandardError, "No files found in the bucket" if key.nil?

        read_csv_headers(s3_client, bucket, key)
      end

      def read_csv_headers(s3_client, bucket, key)
        obj = s3_client.get_object(bucket: bucket, key: key)
        first_line = obj.body.read.to_s.lines.first
        return [] if first_line.nil? || first_line.strip.empty?

        CSV.parse_line(first_line.strip)
      end

      def group_by_table(records, file_name)
        result = {}
        records.each do |entry|
          table_name = file_name
          column_data = {
            column_name: entry,
            type: "string",
            optional: true
          }
          result[table_name] ||= { tablename: table_name, columns: [] }
          result[table_name][:columns] << column_data
        end
        result
      end

      def create_streams(tables)
        tables.values.map do |r|
          Multiwoven::Integrations::Protocol::Stream.new(
            name: r[:tablename],
            action: StreamAction["create"],
            json_schema: convert_to_json_schema(r[:columns])
          )
        end
      end
    end
  end
end
