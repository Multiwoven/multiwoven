# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module GoogleCloudStorage
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        initialize_client(connection_config)

        begin
          # Get the bucket
          bucket_obj = get_bucket

          if bucket_obj.nil? || !bucket_obj.exists?
            return ConnectionStatus.new(
              status: ConnectionStatusType["failed"],
              message: "Bucket '#{@bucket}' not found or you don't have access to it."
            ).to_multiwoven_message
          end

          # List and filter files
          files = list_files(bucket_obj)

          if files.empty?
            return ConnectionStatus.new(
              status: ConnectionStatusType["failed"],
              message: "No #{@file_type} files found in bucket '#{@bucket}' with path '#{@path}'."
            ).to_multiwoven_message
          end

          # Connection successful
          ConnectionStatus.new(
            status: ConnectionStatusType["succeeded"],
            message: "Successfully connected to Google Cloud Storage bucket: #{@bucket}"
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
        initialize_client(connection_config)

        begin
          # Get the bucket
          bucket_obj = get_bucket

          # List and filter files
          files = list_files(bucket_obj)

          # Return empty catalog if no files are found
          if files.empty?
            return Catalog.new(
              streams: []
            ).to_multiwoven_message
          end

          # Get the first file to determine schema
          sample_file = files.first
          file_content = sample_file.download

          json_schema = get_schema_from_file(file_content)

          streams = [
            Multiwoven::Integrations::Protocol::Stream.new(
              name: "#{@bucket}_#{@file_type}_files",
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
        initialize_client(connection_config)

        begin
          # If there's a query in the sync_config, we'll process it
          if sync_config.model && sync_config.model.query && !sync_config.model.query.empty?
            conn = create_connection
            query_string = sync_config.model.query
            query_string = batched_query(query_string, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
            return query(conn, query_string)
          end

          # Get the bucket
          bucket_obj = get_bucket

          # List and filter files
          files = list_files(bucket_obj)

          # Process each file and collect records
          records = []

          files.each do |file|
            # Download the file content
            file_content = file.download

            # Process the file based on its type
            if @file_type == "csv"
              CSV.parse(file_content, headers: true).each do |row|
                records << RecordMessage.new(
                  data: row.to_h,
                  emitted_at: Time.now.to_i
                ).to_multiwoven_message
              end
            elsif @file_type == "parquet"
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

      def create_connection(config = nil)
        initialize_client(config) if config
        DuckDB::Database.open.connect
      end

      def query(conn, query_string)
        records = get_results(conn, query_string)
        records.map do |row|
          RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      private
      def initialize_client(config = nil)
        if config
          config = config.with_indifferent_access
          @project_id = config["project_id"]
          @client_email = config["client_email"]
          @private_key = config["private_key"]
          @bucket = config["bucket"]
          @path = config["path"] || ""
          @file_type = config["file_type"]
          @storage_client = nil # Reset storage client when config changes
        end
      end

      def get_storage_client
        # Cache the storage client to avoid recreating it
        @storage_client ||= create_storage_client
      end

      def get_bucket
        # Get the bucket using the cached storage client
        get_storage_client.bucket(@bucket)
      end

      def get_path_prefix
        # Format the path prefix consistently
        @path.start_with?("/") ? @path[1..-1] : @path
      end

      def list_files(bucket_obj)
        # List files with the given prefix and filter by file type
        prefix = get_path_prefix
        files = bucket_obj.files(prefix: prefix)
        files = files.select { |file| file.name.end_with?(".#{@file_type}") } if files
        files || []
      end

      def get_schema_from_file(file_content)
        if @file_type == "csv"
          csv = CSV.parse(file_content, headers: true)
          headers = csv.headers
          
          # Create a simple schema based on the CSV headers
          properties = {}
          headers.each do |header|
            properties[header] = { "type" => "string" }
          end
          
          {
            "type" => "object",
            "properties" => properties
          }
        elsif @file_type == "parquet"
          # For parquet, we'd need a specialized gem
          # For now, just create a placeholder schema
          {
            "type" => "object",
            "properties" => {
              "data" => { "type" => "object" }
            }
          }
        else
          # Default empty schema
          {
            "type" => "object",
            "properties" => {}
          }
        end
      end

      def get_results(conn, query_string)
        # Get the bucket
        bucket_obj = get_bucket

        # List and filter files
        files = list_files(bucket_obj)

        if files.empty?
          return []
        end

        # Create a temporary directory to store downloaded files
        temp_dir = Dir.mktmpdir("gcs_query")
        
        # Download files to the temporary directory
        temp_files = []
        files.each do |file|
          file_path = File.join(temp_dir, File.basename(file.name))
          file.download(file_path)
          temp_files << file_path
        end
        
        # Register the files with DuckDB
        if @file_type == "csv"
          # Create a view that combines all CSV files
          temp_files.each_with_index do |file_path, index|
            table_name = "temp_csv_#{index}"
            conn.execute("CREATE TABLE #{table_name} AS SELECT * FROM read_csv_auto('#{file_path}');")
            
            # For the first file, create the main view
            if index == 0
              conn.execute("CREATE VIEW gcs_data AS SELECT * FROM #{table_name};")
            else
              # For subsequent files, append to the main view
              conn.execute("DROP VIEW gcs_data;")
              conn.execute("CREATE VIEW gcs_data AS SELECT * FROM temp_csv_0 UNION ALL SELECT * FROM #{table_name};")
            end
          end
        elsif @file_type == "parquet"
          # Create a view that combines all Parquet files
          temp_files.each_with_index do |file_path, index|
            table_name = "temp_parquet_#{index}"
            conn.execute("CREATE TABLE #{table_name} AS SELECT * FROM read_parquet('#{file_path}');")
            
            # For the first file, create the main view
            if index == 0
              conn.execute("CREATE VIEW gcs_data AS SELECT * FROM #{table_name};")
            else
              # For subsequent files, append to the main view
              conn.execute("DROP VIEW gcs_data;")
              conn.execute("CREATE VIEW gcs_data AS SELECT * FROM temp_parquet_0 UNION ALL SELECT * FROM #{table_name};")
            end
          end
        end
        
        # Execute the query
        modified_query = query_string.gsub(/FROM\s+[^\s,;()]+/i, 'FROM gcs_data')
        results = conn.query(modified_query)
        
        # Convert results to an array of hashes
        records = []
        if results && results.columns && !results.columns.empty?
          keys = results.columns.map(&:name)
          results.each do |row|
            records << Hash[keys.zip(row)]
          end
        end
        
        # Clean up temporary files
        FileUtils.remove_entry(temp_dir) if Dir.exist?(temp_dir)
        
        records
      rescue StandardError => e
        handle_exception(e, { context: "GOOGLECLOUDSTORAGE:QUERY:EXCEPTION", type: "error" })
      end

      def batched_query(query, limit, offset)
        # Add LIMIT and OFFSET clauses if they don't already exist
        query = query.strip
        query = query.chomp(";") if query.end_with?(";")
        "#{query} LIMIT #{limit} OFFSET #{offset}"
      end

      def create_storage_client
        # Format the private key properly
        formatted_key = @private_key.gsub('\n', "\n")
        
        # Create a Google Cloud Storage client
        Google::Cloud::Storage.new(
          project_id: @project_id,
          credentials: {
            type: "service_account",
            project_id: @project_id,
            private_key: formatted_key,
            client_email: @client_email
          }
        )
      end
    end
  end
end