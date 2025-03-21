# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module GoogleCloudStorage
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        conn = create_connection(connection_config)
        bucket = conn.bucket(connection_config[:bucket])
        
        unless bucket.exists?
          return ConnectionStatus.new(
            status: ConnectionStatusType["failed"], 
            message: "Bucket '#{connection_config[:bucket]}' does not exist"
          ).to_multiwoven_message
        end
        
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
          context: "GOOGLECLOUDSTORAGE:DISCOVER:EXCEPTION",
          type: "error"
        })
      end

      def write(sync_config, records, _action = "destination_insert")
        records_size = records.size
        log_message_array = []
        write_success = upload_content(sync_config, records)
        write_failure = records_size - write_success
        log_message_array << log_request_response("info", @args, @response)
        tracking_message(write_success, write_failure, log_message_array)
      rescue StandardError => e
        handle_exception(e, {
          context: "GOOGLECLOUDSTORAGE:WRITE:EXCEPTION",
          type: "error",
          sync_id: sync_config.sync_id,
          sync_run_id: sync_config.sync_run_id
        })
      end

      private

      def create_connection(connection_config)
        credentials = parse_credentials(connection_config)
        Google::Cloud::Storage.new(
          project_id: connection_config[:project_id],
          credentials: credentials
        )
      end

      def parse_credentials(connection_config)
        if connection_config[:credentials_json].is_a?(String)
          JSON.parse(connection_config[:credentials_json])
        else
          connection_config[:credentials_json]
        end
      end

      def upload_content(sync_config, records)
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        conn = create_connection(connection_config)
        
        file_name = generate_file_name(connection_config, sync_config.stream.name)
        file_content = generate_file_content(records, connection_config[:file_type])
        
        begin
          @args = ["create", connection_config[:bucket], file_name, file_content.size]
          bucket = conn.bucket(connection_config[:bucket])
          file = bucket.create_file(StringIO.new(file_content), file_name)
          @response = "Successfully uploaded to gs://#{connection_config[:bucket]}/#{file_name}"
          write_success = records.size
        rescue StandardError => e
          handle_exception(e, {
            context: "GOOGLECLOUDSTORAGE:RECORD:WRITE:EXCEPTION",
            type: "error",
            sync_id: sync_config.sync_id,
            sync_run_id: sync_config.sync_run_id
          })
          write_success = 0
        end
        
        write_success
      end

      def generate_file_content(records, file_type)
        # Extract record data from MultiwovenMessages
        data = records.map { |record| record.record.data if record.type == "RECORD" }.compact
        return "" if data.empty?
        
        case file_type.downcase
        when "csv"
          generate_csv_content(data)
        when "json"
          generate_json_content(data)
        else
          raise "Unsupported file type: #{file_type}"
        end
      end

      def generate_csv_content(records)
        require "csv"
        
        CSV.generate do |csv|
          headers = records.first.keys
          csv << headers
          records.each { |record| csv << record.values_at(*headers) }
        end
      end

      def generate_json_content(data)
        JSON.pretty_generate(data)
      end

      def generate_file_name(connection_config, stream_name)
        timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
        path = connection_config[:path].to_s.strip
        path = "#{path}/" if !path.empty? && path[-1] != "/"
        "#{path}#{stream_name}_#{timestamp}.#{connection_config[:file_type]}"
      end
    end
  end
end