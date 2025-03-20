# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module GoogleCloudStorage
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        # Extract the connection parameters
        project_id = connection_config["project_id"]
        client_email = connection_config["client_email"]
        private_key = connection_config["private_key"]
        bucket = connection_config["bucket"]

        # Validate required parameters
        missing_params = []
        missing_params << "project_id" if project_id.nil? || project_id.strip.empty?
        missing_params << "client_email" if client_email.nil? || client_email.strip.empty?
        missing_params << "private_key" if private_key.nil? || private_key.strip.empty?
        missing_params << "bucket" if bucket.nil? || bucket.strip.empty?

        if missing_params.any?
          return ConnectionStatus.new(
            status: ConnectionStatusType["failed"],
            message: "Missing required parameters: #{missing_params.join(', ')}"
          ).to_multiwoven_message
        end

        begin
          require 'google/cloud/storage'

          # Format the private key properly
          formatted_key = private_key.gsub('\n', "\n")

          # Create a Google Cloud Storage client
          storage = Google::Cloud::Storage.new(
            project_id: project_id,
            credentials: {
              type: "service_account",
              project_id: project_id,
              private_key: formatted_key,
              client_email: client_email
            }
          )

          # Check if the bucket exists
          bucket_obj = storage.bucket(bucket)

          if bucket_obj.nil? || !bucket_obj.exists?
            return ConnectionStatus.new(
              status: ConnectionStatusType["failed"],
              message: "Bucket '#{bucket}' not found or you don't have access to it."
            ).to_multiwoven_message
          end

          # Connection successful
          ConnectionStatus.new(
            status: ConnectionStatusType["succeeded"],
            message: "Successfully connected to Google Cloud Storage bucket: #{bucket}"
          ).to_multiwoven_message
        rescue StandardError => e
          ConnectionStatus.new(
            status: ConnectionStatusType["failed"],
            message: "Failed to connect to Google Cloud Storage: #{e.message}"
          ).to_multiwoven_message
        end
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        project_id = connection_config["project_id"]
        client_email = connection_config["client_email"]
        private_key = connection_config["private_key"]
        bucket = connection_config["bucket"]
        path = connection_config["path"] || ""
        file_type = connection_config["file_type"]

        begin
          require 'google/cloud/storage'
          require 'csv'

          # Format the private key properly
          formatted_key = private_key.gsub('\n', "\n")

          # Create a Google Cloud Storage client
          storage = Google::Cloud::Storage.new(
            project_id: project_id,
            credentials: {
              type: "service_account",
              project_id: project_id,
              private_key: formatted_key,
              client_email: client_email
            }
          )

          # Get the bucket
          bucket_obj = storage.bucket(bucket)

          # Prepare the path prefix
          prefix = path.start_with?("/") ? path[1..-1] : path

          # List files in the bucket with the given prefix
          files = bucket_obj.files(prefix: prefix)

          # Filter files by file type
          files = files.select { |file| file.name.end_with?(".#{file_type}") }

          if files.empty?
            return Catalog.new(
              streams: []
            ).to_multiwoven_message
          end

          # Get the first file to determine schema
          sample_file = files.first
          file_content = sample_file.download

          columns = []
          json_schema = {}

          if file_type == "csv"
            csv = CSV.parse(file_content, headers: true)
            headers = csv.headers
            
            # Create a simple schema based on the CSV headers
            properties = {}
            headers.each do |header|
              properties[header] = { "type" => "string" }
            end
            
            json_schema = {
              "type" => "object",
              "properties" => properties
            }
          elsif file_type == "parquet"
            # For parquet, we'd need a specialized gem
            # For now, just create a placeholder schema
            json_schema = {
              "type" => "object",
              "properties" => {
                "data" => { "type" => "object" }
              }
            }
          end

          streams = [
            Multiwoven::Integrations::Protocol::Stream.new(
              name: "#{bucket}_#{file_type}_files",
              action: StreamAction["fetch"],
              json_schema: json_schema
            )
          ]

          catalog = Catalog.new(streams: streams)
          catalog.to_multiwoven_message
        rescue StandardError => e
          handle_exception(e, { context: "GOOGLECLOUDSTORAGE:DISCOVER:EXCEPTION", type: "error" })
        end
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification.with_indifferent_access
        project_id = connection_config["project_id"]
        client_email = connection_config["client_email"]
        private_key = connection_config["private_key"]
        bucket = connection_config["bucket"]
        path = connection_config["path"] || ""
        file_type = connection_config["file_type"]

        begin
          require 'google/cloud/storage'
          require 'csv'

          # Format the private key properly
          formatted_key = private_key.gsub('\n', "\n")

          # Create a Google Cloud Storage client
          storage = Google::Cloud::Storage.new(
            project_id: project_id,
            credentials: {
              type: "service_account",
              project_id: project_id,
              private_key: formatted_key,
              client_email: client_email
            }
          )

          # Get the bucket
          bucket_obj = storage.bucket(bucket)

          # Prepare the path prefix
          prefix = path.start_with?("/") ? path[1..-1] : path

          # List files in the bucket with the given prefix
          files = bucket_obj.files(prefix: prefix)

          # Filter files by file type
          files = files.select { |file| file.name.end_with?(".#{file_type}") }

          # Process each file and collect records
          records = []

          files.each do |file|
            # Download the file content
            file_content = file.download

            # Process the file based on its type
            if file_type == "csv"
              CSV.parse(file_content, headers: true).each do |row|
                records << RecordMessage.new(
                  data: row.to_h,
                  emitted_at: Time.now.to_i
                ).to_multiwoven_message
              end
            elsif file_type == "parquet"
              # We can't process parquet without specialized gems
              # This is just a placeholder - actual implementation requires additional gems
              # For now, just log a warning
              puts "Parquet file processing requires additional gems. Please use CSV format or install necessary parquet gems."
            end
          end

          records
        rescue StandardError => e
          handle_exception(e, {
            context: "GOOGLECLOUDSTORAGE:READ:EXCEPTION",
            type: "error",
            sync_id: sync_config.sync_id,
            sync_run_id: sync_config.sync_run_id
          })
        end
      end
    end
  end
end