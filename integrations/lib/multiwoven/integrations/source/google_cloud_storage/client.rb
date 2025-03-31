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
          bucket_obj = bucket

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
          bucket_obj = bucket

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

          json_schema = schema_from_file(file_content)

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
          # If there's a query in the sync_config, process it
          return process_query(sync_config) if sync_config.model&.query && !sync_config.model.query.empty?

          # Otherwise, read records directly from files
          process_files
        rescue StandardError => e
          handle_exception(e, {
                             context: "GOOGLECLOUDSTORAGE:READ:EXCEPTION",
                             type: "error",
                             sync_id: sync_config.sync_id,
                             sync_run_id: sync_config.sync_run_id
                           })
        end
      end

      def process_query(sync_config)
        conn = create_connection
        query_string = sync_config.model.query
        query_string = batched_query(query_string, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
        query(conn, query_string)
      end

      def process_files
        bucket_obj = bucket
        files = list_files(bucket_obj)
        records = []

        files.each do |file|
          file_content = file.download
          records.concat(process_file_content(file_content))
        end

        records
      end

      def process_file_content(file_content)
        case @file_type
        when "csv"
          process_csv_content(file_content)
        when "parquet"
          process_parquet_content
        else
          []
        end
      end

      def process_csv_content(file_content)
        CSV.parse(file_content, headers: true).map do |row|
          RecordMessage.new(
            data: row.to_h,
            emitted_at: Time.now.to_i
          ).to_multiwoven_message
        end
      end

      def process_parquet_content
        # We can't process parquet without specialized gems
        # This is just a placeholder - actual implementation requires additional gems
        puts "Parquet file processing requires additional gems. Please use CSV format or install necessary parquet gems."
        []
      end

      def create_connection(config = nil)
        initialize_client(config) if config
        DuckDB::Database.open.connect
      end

      def query(conn, query_string)
        records = results(conn, query_string)
        records.map do |row|
          RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      def results(conn, query_string)
        # Get the bucket and list files
        files = list_files(bucket)
        return [] if files.empty?

        # Download files and prepare for query
        temp_dir = Dir.mktmpdir("gcs_query")
        temp_files = download_files_to_temp_dir(files, temp_dir)

        begin
          # Register files with DuckDB and create views
          create_duckdb_views(conn, temp_files)

          # Execute the query and process results
          records = execute_query_and_process_results(conn, query_string)

          records
        rescue StandardError => e
          handle_exception(e, { context: "GOOGLECLOUDSTORAGE:QUERY:EXCEPTION", type: "error" })
        ensure
          # Clean up temporary files
          FileUtils.remove_entry(temp_dir) if Dir.exist?(temp_dir)
        end
      end

      def download_files_to_temp_dir(files, temp_dir)
        temp_files = []
        files.each do |file|
          file_path = File.join(temp_dir, File.basename(file.name))
          file.download(file_path)
          temp_files << file_path
        end
        temp_files
      end

      def create_duckdb_views(conn, temp_files)
        case @file_type
        when "csv"
          create_csv_views(conn, temp_files)
        when "parquet"
          create_parquet_views(conn, temp_files)
        end
      end

      def create_csv_views(conn, temp_files)
        temp_files.each_with_index do |file_path, index|
          table_name = "temp_csv_#{index}"
          conn.execute("CREATE TABLE #{table_name} AS SELECT * FROM read_csv_auto('#{file_path}');")
          if index.zero?
            conn.execute("CREATE VIEW gcs_data AS SELECT * FROM #{table_name};")
          else
            conn.execute("DROP VIEW gcs_data;")
            conn.execute("CREATE VIEW gcs_data AS SELECT * FROM temp_csv_0 UNION ALL SELECT * FROM #{table_name};")
          end
        end
      end

      def create_parquet_views(conn, temp_files)
        temp_files.each_with_index do |file_path, index|
          table_name = "temp_parquet_#{index}"
          conn.execute("CREATE TABLE #{table_name} AS SELECT * FROM read_parquet('#{file_path}');")
          if index.zero?
            conn.execute("CREATE VIEW gcs_data AS SELECT * FROM #{table_name};")
          else
            conn.execute("DROP VIEW gcs_data;")
            conn.execute("CREATE VIEW gcs_data AS SELECT * FROM temp_parquet_0 UNION ALL SELECT * FROM #{table_name};")
          end
        end
      end

      def execute_query_and_process_results(conn, query_string)
        # Execute the query
        modified_query = query_string.gsub(/FROM\s+[^\s,;()]+/i, "FROM gcs_data")
        results = conn.query(modified_query)

        # Convert results to an array of hashes
        records = []
        if results&.columns && !results.columns.empty?
          keys = results.columns.map(&:name)
          results.each do |row|
            records << Hash[keys.zip(row)]
          end
        end
        records
      end

      def batched_query(query, limit, offset)
        # Add LIMIT and OFFSET clauses if they don't already exist
        query = query.strip.chomp(";")
        "#{query} LIMIT #{limit} OFFSET #{offset}"
      end

      private

      def initialize_client(config = nil)
        return unless config

        config = config.with_indifferent_access
        @project_id = config["project_id"]
        @client_email = config["client_email"]
        @private_key = config["private_key"]
        @bucket = config["bucket"]
        @path = config["path"] || ""
        @file_type = config["file_type"]
        @storage_client = nil # Reset storage client when config changes
      end

      def storage_client
        @storage_client ||= create_storage_client
      end

      def bucket
        storage_client.bucket(@bucket)
      end

      def path_prefix
        @path.start_with?("/") ? @path[1..] : @path
      end

      def list_files(bucket_obj)
        # List files with the given prefix and filter by file type
        prefix = path_prefix
        files = bucket_obj.files(prefix: prefix)
        files = files.select { |file| file.name.end_with?(".#{@file_type}") } if files
        files || []
      end

      def schema_from_file(file_content)
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
