# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module GoogleCloudStorage
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      INSTALL_HTTPFS_QUERY = "INSTALL httpfs; LOAD httpfs;"

      @session_name = ""
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        @session_name = "connection-#{connection_config[:project_id]}-#{connection_config[:bucket]}"
        conn = create_connection(connection_config)
        path = build_path(connection_config)
        get_results(conn, "DESCRIBE SELECT * FROM '#{path}';")
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        @session_name = "discover-#{connection_config[:project_id]}-#{connection_config[:bucket]}"
        conn = create_connection(connection_config)
        # If pulling from multiple files, all files must have the same schema
        path = build_path(connection_config)
        records = get_results(conn, "DESCRIBE SELECT * FROM '#{path}';")
        columns = build_discover_columns(records)
        streams = [Multiwoven::Integrations::Protocol::Stream.new(name: path, action: StreamAction["fetch"], json_schema: convert_to_json_schema(columns))]
        catalog = Catalog.new(streams: streams)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, { context: "GOOGLECLOUDSTORAGE:DISCOVER:EXCEPTION", type: "error" })
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification.with_indifferent_access
        @session_name = "#{sync_config.sync_id}-#{sync_config.source.name}-#{sync_config.destination.name}"
        conn = create_connection(connection_config)
        query = sync_config.model.query
        query = batched_query(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
        query(conn, query)
      rescue StandardError => e
        handle_exception(e, {
                           context: "GOOGLECLOUDSTORAGE:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def get_auth_data(connection_config)
        session = @session_name.gsub(/\s+/, "-")
        @session_name = ""
        # Create a credentials hash from the connection config
        {
          "type" => "service_account",
          "project_id" => connection_config[:project_id],
          "private_key" => connection_config[:private_key].gsub('\n', "\n"),
          "client_email" => connection_config[:client_email]
        }
      end

      def create_connection(connection_config)
        # In the case when previewing a query
        @session_name = "preview-#{connection_config[:project_id]}-#{connection_config[:bucket]}" if @session_name.to_s.empty?
        auth_data = get_auth_data(connection_config)
        conn = DuckDB::Database.open.connect
        # Install and/or Load the HTTPFS extension
        conn.execute(INSTALL_HTTPFS_QUERY)
        
        # Set up GCS credentials in DuckDB
        secret_query = "
          CREATE SECRET gcs_source (
            TYPE GCS,
            PROJECT_ID '#{auth_data["project_id"]}',
            CLIENT_EMAIL '#{auth_data["client_email"]}',
            PRIVATE_KEY '#{auth_data["private_key"]}'
          );
        "
        get_results(conn, secret_query)
        conn
      end

      def build_path(connection_config)
        path = connection_config[:path]
        path = "#{path}/" if path.to_s.strip.empty? || path[-1] != "/"
        "gs://#{connection_config[:bucket]}#{path}*.#{connection_config[:file_type]}"
      end

      def get_results(conn, query)
        results = conn.query(query)
        hash_array_values(results)
      end

      def query(conn, query)
        records = get_results(conn, query)
        records.map do |row|
          RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      def hash_array_values(describe)
        keys = describe.columns.map(&:name)
        describe.map do |row|
          Hash[keys.zip(row)]
        end
      end

      def build_discover_columns(describe_results)
        describe_results.map do |row|
          type = column_schema_helper(row["column_type"])
          {
            column_name: row["column_name"],
            type: type
          }
        end
      end

      def column_schema_helper(column_type)
        case column_type
        when "VARCHAR", "BIT", "DATE", "TIME", "TIMESTAMP", "UUID"
          "string"
        when "DOUBLE"
          "number"
        when "BIGINT", "HUGEINT", "INTEGER", "SMALLINT"
          "integer"
        when "BOOLEAN"
          "boolean"
        else
          "string" # Default to string for unknown types
        end
      end

      def convert_to_json_schema(columns)
        properties = {}
        columns.each do |column|
          properties[column[:column_name]] = { "type" => column[:type] }
        end
        { "type" => "object", "properties" => properties }
      end

      def batched_query(query, limit, offset)
        # Add LIMIT and OFFSET clauses if they don't already exist
        query = query.strip
        query = query.chomp(";") if query.end_with?(";")
        "#{query} LIMIT #{limit} OFFSET #{offset}"
      end
    end
  end
end