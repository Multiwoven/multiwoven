# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Audience
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        # Extract user_id and audience_id from connection_config
        user_id = connection_config["user_id"]
        audience_id = connection_config["audience_id"]
        
        # Validate required fields
        if user_id.nil? || user_id.empty? || audience_id.nil? || audience_id.empty?
          return ConnectionStatus.new(
            status: ConnectionStatusType["failed"],
            message: "User ID and Audience ID are required."
          ).to_multiwoven_message
        end
        
        # Use environment variables for credentials
        project_id = ENV['AUDIENCE_PROJECT_ID']
        client_email = ENV['AUDIENCE_CLIENT_EMAIL']
        private_key = ENV['AUDIENCE_PRIVATE_KEY']
        bucket = ENV['AUDIENCE_BUCKET']
        
        # Generate path based on User ID and Audience ID
        path = generate_path(user_id, audience_id)
        # File type is fixed as CSV
        file_type = "csv"

        begin
          # Create a Google Cloud Storage client
          storage = create_storage_client(project_id, client_email, private_key)

          # Check if the bucket exists
          bucket_obj = storage.bucket(bucket)

          if bucket_obj.nil? || !bucket_obj.exists?
            return ConnectionStatus.new(
              status: ConnectionStatusType["failed"],
              message: "Bucket '#{bucket}' not found or you don't have access to it."
            ).to_multiwoven_message
          end

          # Prepare the path prefix
          prefix = path.start_with?("/") ? path[1..-1] : path

          # List files in the bucket with the given prefix
          files = bucket_obj.files(prefix: prefix)

          # Filter files by file type (CSV)
          files = files.select { |file| file.name.end_with?(".csv") }

          if files.empty?
            return ConnectionStatus.new(
              status: ConnectionStatusType["failed"],
              message: "No CSV files found for User ID '#{user_id}' and Audience ID '#{audience_id}'."
            ).to_multiwoven_message
          end

          # Connection successful
          ConnectionStatus.new(
            status: ConnectionStatusType["succeeded"],
            message: "Successfully connected to Audience data source for User ID '#{user_id}' and Audience ID '#{audience_id}'"
          ).to_multiwoven_message
        rescue StandardError => e
          ConnectionStatus.new(
            status: ConnectionStatusType["failed"],
            message: "Failed to connect to Audience data source: #{e.message}"
          ).to_multiwoven_message
        end
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        # Extract user_id and audience_id from connection_config
        user_id = connection_config["user_id"]
        audience_id = connection_config["audience_id"]
        
        # Use environment variables for credentials
        project_id = ENV['AUDIENCE_PROJECT_ID']
        client_email = ENV['AUDIENCE_CLIENT_EMAIL']
        private_key = ENV['AUDIENCE_PRIVATE_KEY']
        bucket = ENV['AUDIENCE_BUCKET']
        
        # Generate path based on User ID and Audience ID
        path = generate_path(user_id, audience_id)
        # File type is fixed as CSV
        file_type = "csv"

        begin
          require 'csv'

          # Create a Google Cloud Storage client
          storage = create_storage_client(project_id, client_email, private_key)

          # Get the bucket
          bucket_obj = storage.bucket(bucket)

          # Prepare the path prefix
          prefix = path.start_with?("/") ? path[1..-1] : path

          # List files in the bucket with the given prefix
          files = bucket_obj.files(prefix: prefix)

          # Filter files by file type (CSV)
          files = files.select { |file| file.name.end_with?(".csv") }

          # Return empty catalog if no files are found
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
              name: "audience_data_#{user_id}_#{audience_id}",
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
        connection_config = sync_config.source.connection_specification.with_indifferent_access
        # Extract user_id and audience_id from connection_config
        user_id = connection_config["user_id"]
        audience_id = connection_config["audience_id"]
        
        # Use environment variables for credentials
        project_id = ENV['AUDIENCE_PROJECT_ID']
        client_email = ENV['AUDIENCE_CLIENT_EMAIL']
        private_key = ENV['AUDIENCE_PRIVATE_KEY']
        bucket = ENV['AUDIENCE_BUCKET']
        
        # Generate path based on User ID and Audience ID
        path = generate_path(user_id, audience_id)
        # File type is fixed as CSV
        file_type = "csv"

        begin
          # If there's a query in the sync_config, we'll process it
          if sync_config.model && sync_config.model.query && !sync_config.model.query.empty?
            conn = create_connection(connection_config)
            query_string = sync_config.model.query
            query_string = batched_query(query_string, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
            return query(conn, query_string)
          end

          require 'csv'

          # Create a Google Cloud Storage client
          storage = create_storage_client(project_id, client_email, private_key)

          # Get the bucket
          bucket_obj = storage.bucket(bucket)

          # Prepare the path prefix
          prefix = path.start_with?("/") ? path[1..-1] : path

          # List files in the bucket with the given prefix
          files = bucket_obj.files(prefix: prefix)

          # Filter files by file type (CSV)
          files = files.select { |file| file.name.end_with?(".csv") } if files

          # Process each file and collect records
          records = []

          files.each do |file|
            # Download the file content
            file_content = file.download

            # Process the CSV file
            CSV.parse(file_content, headers: true).each do |row|
              records << RecordMessage.new(
                data: row.to_h,
                emitted_at: Time.now.to_i
              ).to_multiwoven_message
            end
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
        # For Audience, we'll create a connection configuration that can be used by our query method
        config = config.with_indifferent_access
        user_id = config["user_id"]
        audience_id = config["audience_id"]
        
        {
          project_id: ENV['AUDIENCE_PROJECT_ID'],
          client_email: ENV['AUDIENCE_CLIENT_EMAIL'],
          private_key: ENV['AUDIENCE_PRIVATE_KEY'],
          bucket: ENV['AUDIENCE_BUCKET'],
          path: generate_path(user_id, audience_id),
          file_type: "csv"
        }
      end

      def query(conn, query_string)
        records = get_results(conn, query_string)
        records.map do |row|
          RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      private

      def generate_path(user_id, audience_id)
        # Generate a path based on User ID and Audience ID
        # Format: /{user_id}/{audience_id}
        "/#{user_id}/#{audience_id}"
      end

      def get_results(conn, query_string)
        # Extract connection configuration from conn
        project_id = conn[:project_id]
        client_email = conn[:client_email]
        private_key = conn[:private_key]
        bucket = conn[:bucket]
        path = conn[:path] || ""
        file_type = conn[:file_type]

        require 'csv'
        require 'duckdb'
        require 'fileutils'
        require 'tmpdir'

        # Create a Google Cloud Storage client
        storage = create_storage_client(project_id, client_email, private_key)

        # Get the bucket
        bucket_obj = storage.bucket(bucket)

        # Prepare the path prefix
        prefix = path.start_with?("/") ? path[1..-1] : path

        # List files in the bucket with the given prefix
        files = bucket_obj.files(prefix: prefix)

        # Filter files by file type (CSV)
        files = files.select { |file| file.name.end_with?(".csv") } if files

        if !files || files.empty?
          return []
        end

        # Create a temporary directory to store downloaded files
        temp_dir = Dir.mktmpdir("audience_query")
        
        # Download files to the temporary directory
        temp_files = []
        files.each do |file|
          file_path = File.join(temp_dir, File.basename(file.name))
          file.download(file_path)
          temp_files << file_path
        end
        
        # Create a DuckDB connection to query the files
        conn = DuckDB::Database.open.connect
        
        # Register the CSV files with DuckDB
        # Create a view that combines all CSV files
        temp_files.each_with_index do |file_path, index|
          table_name = "temp_csv_#{index}"
          conn.execute("CREATE TABLE #{table_name} AS SELECT * FROM read_csv_auto('#{file_path}');")
          
          # For the first file, create the main view
          if index == 0
            conn.execute("CREATE VIEW audience_data AS SELECT * FROM #{table_name};")
          else
            # For subsequent files, append to the main view
            conn.execute("DROP VIEW audience_data;")
            conn.execute("CREATE VIEW audience_data AS SELECT * FROM temp_csv_0 UNION ALL SELECT * FROM #{table_name};")
          end
        end
        
        # Execute the query
        modified_query = query_string.gsub(/FROM\s+[^\s,;()]+/i, 'FROM audience_data')
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
        handle_exception(e, { context: "AUDIENCE:QUERY:EXCEPTION", type: "error" })
      end

      def batched_query(query, limit, offset)
        # Add LIMIT and OFFSET clauses if they don't already exist
        query = query.strip
        query = query.chomp(";") if query.end_with?(";")
        "#{query} LIMIT #{limit} OFFSET #{offset}"
      end

      def create_storage_client(project_id, client_email, private_key)
        # Format the private key properly
        formatted_key = private_key.gsub('\n', "\n")
        
        # Create a Google Cloud Storage client
        Google::Cloud::Storage.new(
          project_id: project_id,
          credentials: {
            type: "service_account",
            project_id: project_id,
            private_key: formatted_key,
            client_email: client_email
          }
        )
      end
    end
  end
end
