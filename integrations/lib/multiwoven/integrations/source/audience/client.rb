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
          # Log the exception
          Rails.logger.error("AUDIENCE:DISCOVER:EXCEPTION: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n")) if e.backtrace

          # Create a log message
          log_message = LogMessage.new(
            level: "error",
            message: e.message,
            name: "AUDIENCE:DISCOVER:EXCEPTION"
          )

          # Return as a MultiwovenMessage
          log_message.to_multiwoven_message
        end
      end

      def read(sync_config)
        begin
          connection_config = sync_config.source.connection_specification
          initialize_client(connection_config)

          # Store connection config in an instance variable to ensure it's available for all method calls
          @current_connection_config = connection_config

          # If there's a query in the sync_config, we'll process it
          # Check if query is a string before calling empty? on it
          if sync_config.model && sync_config.model.query && sync_config.model.query.is_a?(String) && !sync_config.model.query.empty?
            conn = create_connection(connection_config)
            query_string = sync_config.model.query
            query_string = batched_query(query_string, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
            result = query(conn, query_string)
            # If result is an error message, return it directly
            return result if result.is_a?(Multiwoven::Integrations::Protocol::MultiwovenMessage)
            return result
          end

          # Create a Google Cloud Storage client
          storage = create_storage_client

          # Get the bucket
          bucket_obj = storage.bucket(@bucket)

          # List files in the bucket with the given prefix
          files = list_files(bucket_obj)

          if files.empty?
            return LogMessage.new(
              level: "error",
              message: "No CSV files found for User ID '#{@user_id}' and Audience ID '#{@audience_id}'.",
              name: "AUDIENCE:READ:NO_FILES"
            ).to_multiwoven_message
          end

          # Get the latest file based on timestamp in filename
          latest_file = get_latest_file(files)

          # Instead of downloading the file, use DuckDB to read directly from GCS
          conn = create_connection(@current_connection_config)

          # Check file size and compression
          file_size_mb = latest_file.size.to_f / (1024 * 1024)
          is_compressed = latest_file.content_encoding == "gzip"

          # Use DuckDB to read the file directly from GCS
          gcs_url = "gcs://#{@bucket}/#{latest_file.name}"

          # Create a simple query if none was provided
          query_string = "SELECT * FROM read_csv_auto('#{gcs_url}', compression='auto')"

          # Add batching if needed
          query_string = batched_query(query_string, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?

          # Use the query method which already has error handling
          result = query(conn, query_string)
          return result

        rescue StandardError => e
          Rails.logger.error("AUDIENCE:READ:EXCEPTION: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n")) if e.backtrace

          LogMessage.new(
            level: "error",
            message: "Error reading Audience data: #{e.message}",
            name: "AUDIENCE:READ:EXCEPTION"
          ).to_multiwoven_message
        end
      end

      def create_connection(config)
        initialize_client(config) if config
        conn = DuckDB::Database.open.connect
        # Install and/or Load the HTTPFS extension (required for GCS)
        conn.execute('INSTALL httpfs;')
        conn.execute('LOAD httpfs;')
        # Set up GCS configuration using DuckDB CREATE SECRET
        # See: https://duckdb.org/docs/stable/guides/network_cloud_storage/gcs_import.html
        secret_query = """
          CREATE SECRET gcs_source (
            TYPE GCS,
            KEY_ID '#{@key_id}',
            SECRET '#{@key_secret}'
          );
        """
        conn.execute(secret_query)
        conn
      end

      def query(conn, query_string)
        result = get_results(query_string)

        # If result is already a MultiwovenMessage (error case), return it directly
        return result if result.is_a?(Multiwoven::Integrations::Protocol::MultiwovenMessage)

        # Otherwise, map the records to RecordMessages
        result.map do |row|
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
        @key_id = ENV['AUDIENCE_KEY_ID']
        @key_secret = ENV['AUDIENCE_KEY_SECRET']
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
        begin
          # If instance variables are nil, reinitialize from stored connection config
          if (@user_id.nil? || @audience_id.nil?) && @current_connection_config
            initialize_client(@current_connection_config)
            
            # If still nil after initialization, log an error but continue with default values
            if @user_id.nil? || @audience_id.nil?
              Rails.logger.error("Missing required parameters: user_id=#{@user_id.inspect}, audience_id=#{@audience_id.inspect}")
            end
          end

          # Create a Google Cloud Storage client
          storage = create_storage_client
          bucket_obj = storage.bucket(@bucket)
          files = list_files(bucket_obj)
          if files.empty?
            return []
          end

          latest_file = get_latest_file(files)
          
          # Check file size and compression
          file_size_mb = latest_file.size.to_f / (1024 * 1024)
          is_compressed = latest_file.content_encoding == "gzip"

          # If file is too large for preview, add a small LIMIT to the query
          if file_size_mb > 50 && !query_string.to_s.downcase.include?("limit")
            query_string = query_string.to_s.strip
            query_string += " LIMIT 100" unless query_string.empty?
          end

          conn = create_connection(@current_connection_config)

          gcs_url = "gcs://#{@bucket}/#{latest_file.name}"

          # Initialize results variable outside the timeout block
          results = nil

          # Set a timeout for the query
          begin
            Timeout.timeout(180) do  
              # First, let's install and load required extensions for GCS access
              conn.execute("INSTALL httpfs; LOAD httpfs;")
              
              # Prepare the query with explicit type handling for phone columns
              # We'll force the problematic columns to be VARCHAR and use a larger sample size
              types_param = "types={'SKIPTRACE_B2B_PHONE': 'VARCHAR', 'PHONE': 'VARCHAR', 'MOBILE': 'VARCHAR', 'HOME_PHONE': 'VARCHAR', 'WORK_PHONE': 'VARCHAR'}"
              compression_param = is_compressed ? "compression='auto'" : ""
              all_varchar_param = "ALL_VARCHAR=TRUE"
              sample_size_param = "sample_size=-1"  # Use all rows for sampling
              ignore_errors_param = "ignore_errors=true"
              
              # Combine all parameters
              csv_params = [compression_param, all_varchar_param, sample_size_param, types_param, ignore_errors_param].reject(&:empty?).join(", ")
              
              # Prepare the final query
              final_query = if query_string.to_s.strip.empty?
                # If no query provided, use a standard query with all our parameters
                "SELECT * FROM read_csv_auto('#{gcs_url}', #{csv_params})"
              else
                # If query exists, replace the FROM clause with our enhanced CSV reader
                query_string.gsub(/FROM\s+[^\s,;()]+/i, "FROM read_csv_auto('#{gcs_url}', #{csv_params})")
              end
              
              # Add LIMIT if not already present and this is a preview query
              if !final_query.downcase.include?("limit") && query_string.to_s.include?("LIMIT")
                final_query += " LIMIT 1000"
              end
              
              # Log the query for debugging
              Rails.logger.info("AUDIENCE: Executing DuckDB query: #{final_query}")
              
              # Assign to the results variable that's in the outer scope
              results = conn.query(final_query) 
            end

            # Now results is accessible here
          rescue Timeout::Error => timeout_error
            Rails.logger.error("AUDIENCE:TIMEOUT: DuckDB query timed out after 180 seconds")
            return LogMessage.new(
              level: "error",
              message: "DuckDB query timed out after 180 seconds. The GCS file may be too large or there might be connectivity issues.",
              name: "AUDIENCE:DUCKDB:TIMEOUT"
            ).to_multiwoven_message
          rescue => duckdb_error
            Rails.logger.error("AUDIENCE:DUCKDB:ERROR: #{duckdb_error.message}\n#{duckdb_error.backtrace.join("\n")}")
            return LogMessage.new(
              level: "error",
              message: "DuckDB error: #{duckdb_error.message}",
              name: "AUDIENCE:DUCKDB:EXCEPTION"
            ).to_multiwoven_message
          end

          records = []
          if results && results.columns && !results.columns.empty?
            keys = results.columns.map(&:name)
            results.each do |row|
              records << Hash[keys.zip(row)]
            end
          end
          records
        rescue => e
          Rails.logger.error("AUDIENCE:GET_RESULTS:EXCEPTION: #{e.message}\n#{e.backtrace.join("\n")}")
          return LogMessage.new(
            level: "error",
            message: "Audience get_results error: #{e.message}",
            name: "AUDIENCE:GET_RESULTS:EXCEPTION"
          ).to_multiwoven_message
        end
      end

      def batched_query(query, limit, offset)
        # Add LIMIT and OFFSET clauses if they don't already exist
        query = query.strip
        query = query.chomp(";") if query.end_with?(";")
        "#{query} LIMIT #{limit} OFFSET #{offset}"
      end

      def create_storage_client
        # Check if required credentials are present
        if @private_key.nil? || @project_id.nil? || @client_email.nil?
          error_message = "Missing required Google Cloud Storage credentials"
          Rails.logger.error("AUDIENCE:CREATE_STORAGE_CLIENT:ERROR: #{error_message}")
          Rails.logger.error("AUDIENCE:ENV_VARS: project_id=#{@project_id.nil? ? 'nil' : 'present'}, client_email=#{@client_email.nil? ? 'nil' : 'present'}, private_key=#{@private_key.nil? ? 'nil' : 'present'}")
          raise StandardError, error_message
        end

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
