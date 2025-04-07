# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Audience
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        initialize_client(connection_config)
        
        # Validate required fields
        if @user_id.nil? || @user_id.empty? || @audience_id.nil? || @audience_id.empty?
          return ConnectionStatus.new(
            status: ConnectionStatusType["failed"],
            message: "User ID and Audience ID are required."
          ).to_multiwoven_message
        end
        
        begin
          # Create a Google Cloud Storage client
          storage = create_storage_client

          # Check if the bucket exists
          bucket_obj = storage.bucket(@bucket)

          if bucket_obj.nil? || !bucket_obj.exists?
            return ConnectionStatus.new(
              status: ConnectionStatusType["failed"],
              message: "Bucket '#{@bucket}' not found or you don't have access to it."
            ).to_multiwoven_message
          end

          # List files in the bucket with the given prefix
          files = list_files(bucket_obj)

          if files.empty?
            return ConnectionStatus.new(
              status: ConnectionStatusType["failed"],
              message: "No CSV files found for User ID '#{@user_id}' and Audience ID '#{@audience_id}'."
            ).to_multiwoven_message
          end

          # Connection successful
          ConnectionStatus.new(
            status: ConnectionStatusType["succeeded"],
            message: "Successfully connected to Audience data source for User ID '#{@user_id}' and Audience ID '#{@audience_id}'"
          ).to_multiwoven_message
        rescue StandardError => e
          ConnectionStatus.new(
            status: ConnectionStatusType["failed"],
            message: "Failed to connect to Audience data source: #{e.message}"
          ).to_multiwoven_message
        end
      end

      def discover(connection_config)
        initialize_client(connection_config)

        begin
          # Create a Google Cloud Storage client
          storage = create_storage_client

          # Get the bucket
          bucket_obj = storage.bucket(@bucket)

          # List files in the bucket with the given prefix
          files = list_files(bucket_obj)

          # Return empty catalog if no files are found
          if files.empty?
            return Catalog.new(
              streams: []
            ).to_multiwoven_message
          end

          # Get the latest file to determine schema
          latest_file = get_latest_file(files)
          file_content = latest_file.download

          # Process CSV file to determine schema
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

          streams = [
            Multiwoven::Integrations::Protocol::Stream.new(
              name: "audience_data_#{@user_id}_#{@audience_id}",
              action: StreamAction["fetch"],
              json_schema: json_schema
            )
          ]

          catalog = Catalog.new(streams: streams)
          catalog.to_multiwoven_message
        rescue StandardError => e
          handle_exception(e, { context: "AUDIENCE:DISCOVER:EXCEPTION", type: "error" })
        end
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification
        initialize_client(connection_config)

        begin
          # If there's a query in the sync_config, we'll process it
          if sync_config.model && sync_config.model.query && !sync_config.model.query.empty?
            conn = create_connection(connection_config)
            query_string = sync_config.model.query
            query_string = batched_query(query_string, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
            return query(conn, query_string)
          end

          # Create a Google Cloud Storage client
          storage = create_storage_client

          # Get the bucket
          bucket_obj = storage.bucket(@bucket)

          # List files in the bucket with the given prefix
          files = list_files(bucket_obj)

          # Get the latest file based on timestamp in filename
          latest_file = get_latest_file(files)
          
          # Download the file content
          file_content = latest_file.download

          # Process the CSV file
          records = []
          CSV.parse(file_content, headers: true).each do |row|
            records << RecordMessage.new(
              data: row.to_h,
              emitted_at: Time.now.to_i
            ).to_multiwoven_message
          end

          records
        rescue StandardError => e
          handle_exception(e, {
            context: "AUDIENCE:READ:EXCEPTION",
            type: "error",
            sync_id: sync_config.sync_id,
            sync_run_id: sync_config.sync_run_id
          })
        end
      end

      def create_connection(config)
        initialize_client(config) if config
        # Create a DuckDB connection to query the file
        @duckdb_conn = DuckDB::Database.open.connect
      end

      def query(conn, query_string)
        records = get_results(query_string)
        records.map do |row|
          RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      private

      def initialize_client(connection_config)
        connection_config = connection_config.with_indifferent_access
        @user_id = connection_config["user_id"]
        @audience_id = connection_config["audience_id"]
        @project_id = ENV['AUDIENCE_PROJECT_ID']
        @client_email = ENV['AUDIENCE_CLIENT_EMAIL']
        @private_key = ENV['AUDIENCE_PRIVATE_KEY']
        @bucket = ENV['AUDIENCE_BUCKET']
        @path = generate_path(@user_id, @audience_id)
        @file_type = "csv"
      end

      def generate_path(user_id, audience_id)
        # Generate a path based on User ID and Audience ID
        # Format: /{user_id}/{audience_id}
        "csv/#{user_id}/#{audience_id}"
      end

      def list_files(bucket_obj)
        # Prepare the path prefix
        prefix = @path.start_with?("/") ? @path[1..-1] : @path

        # List files in the bucket with the given prefix
        files = bucket_obj.files(prefix: prefix)

        # Filter files by file type
        files = files.select { |file| file.name.end_with?(".#{@file_type}") } if files
        
        files || []
      end

      def get_latest_file(files)
        # Return nil if no files are provided
        return nil if files.nil? || files.empty?
        
        # Extract timestamp from filename and find the latest file
        # Expected filename format: something_YYYYMMDD_HHMMSS.csv or something_YYYYMMDD.csv
        latest_file = files.max_by do |file|
          filename = File.basename(file.name)
          # Try to extract timestamp using different patterns
          timestamp = nil
          
          # Try pattern with date and time (YYYYMMDD_HHMMSS)
          if filename =~ /(\d{8}_\d{6})/
            timestamp = $1
          # Try pattern with just date (YYYYMMDD)
          elsif filename =~ /(\d{8})/
            timestamp = $1
          end
          
          # If no timestamp found, use the file's updated_at attribute as fallback
          timestamp || file.updated_at.to_s
        end
        
        latest_file
      end

      def get_results(query_string)
        # Create a Google Cloud Storage client
        storage = create_storage_client

        # Get the bucket
        bucket_obj = storage.bucket(@bucket)

        # List files in the bucket with the given prefix
        files = list_files(bucket_obj)

        if files.empty?
          return []
        end

        # Get the latest file based on timestamp in filename
        latest_file = get_latest_file(files)
        
        # Create a temporary directory to store downloaded files
        temp_dir = Dir.mktmpdir("audience_query")
        
        # Download only the latest file to the temporary directory
        file_path = File.join(temp_dir, File.basename(latest_file.name))
        latest_file.download(file_path)
        
        # Use the DuckDB connection from create_connection
        conn = @duckdb_conn
        
        # Create a safe table name by replacing any non-alphanumeric characters with underscores
        safe_table_name = "audience_data_#{@user_id.gsub(/[^a-zA-Z0-9]/, '_')}_#{@audience_id.gsub(/[^a-zA-Z0-9]/, '_')}"
        
        # Register the CSV file with DuckDB - use all_varchar=1 to prevent type conversion errors
        conn.execute("CREATE TABLE \"#{safe_table_name}\" AS SELECT * FROM read_csv_auto('#{file_path}', all_varchar=1);")
        
        # Execute the query - use double quotes for table names to handle special characters
        modified_query = query_string.gsub(/FROM\s+[^\s,;()]+/i, "FROM \"#{safe_table_name}\"")
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
        # Re-raise the exception to be handled by the query method
        raise e
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
