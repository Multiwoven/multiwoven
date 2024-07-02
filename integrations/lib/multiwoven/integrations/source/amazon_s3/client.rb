# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module AmazonS3
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      @session_name = ""
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        @session_name = "connection-#{connection_config[:region]}-#{connection_config[:bucket]}"
        conn = create_connection(connection_config)
        path = build_path(connection_config)
        get_results(conn, "DESCRIBE SELECT * FROM '#{path}';")
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        @session_name = "discover-#{connection_config[:region]}-#{connection_config[:bucket]}"
        conn = create_connection(connection_config)
        # If pulling from multiple files, all files must have the same schema
        path = build_path(connection_config)
        records = get_results(conn, "DESCRIBE SELECT * FROM '#{path}';")
        columns = build_discover_columns(records)
        streams = [Multiwoven::Integrations::Protocol::Stream.new(name: path, action: StreamAction["fetch"], json_schema: convert_to_json_schema(columns))]
        catalog = Catalog.new(streams: streams)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, { context: "AMAZONS3:DISCOVER:EXCEPTION", type: "error" })
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
                           context: "AMAZONS3:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def get_auth_data(connection_config)
        session = @session_name
        @session_name = ""
        if connection_config[:auth_type] == "user"
          Aws::Credentials.new(connection_config[:access_id], connection_config[:secret_access])
        elsif connection_config[:auth_type] == "role"
          sts_client = Aws::STS::Client.new(region: connection_config[:region])
          resp = sts_client.assume_role({
                                          role_arn: connection_config[:arn],
                                          role_session_name: session
                                        })
          Aws::Credentials.new(
            resp.credentials.access_key_id,
            resp.credentials.secret_access_key,
            resp.credentials.session_token
          )
        end
      end

      def create_connection(connection_config)
        # In the case when previewing a query
        @session_name = "preview-#{connection_config[:region]}-#{connection_config[:bucket]}" if @session_name.to_s.empty?
        auth_data = get_auth_data(connection_config)
        conn = DuckDB::Database.open.connect
        # Set up S3 configuration
        secret_query = "
              CREATE SECRET amazons3_source (
              TYPE S3,
              KEY_ID '#{auth_data.credentials.access_key_id}',
              SECRET '#{auth_data.credentials.secret_access_key}',
              REGION '#{connection_config[:region]}',
              SESSION_TOKEN '#{auth_data.credentials.session_token}'
          );
        "
        get_results(conn, secret_query)
        conn
      end

      def build_path(connection_config)
        path = connection_config[:path]
        path = "#{path}/" if path.to_s.strip.empty? || path[-1] != "/"
        "s3://#{connection_config[:bucket]}#{path}*.#{connection_config[:file_type]}"
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
        end
      end
    end
  end
end
