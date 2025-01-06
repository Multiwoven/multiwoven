# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Sftp
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        if @sftp.stat!(@remote_file_path)
          success_status
        else
          failure_status(nil)
        end
      rescue StandardError => e
        handle_exception(e, {
                           context: "SFTP:CHECK_CONNECTION:EXCEPTION",
                           type: "error"
                         })
        failure_status(e)
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        db = create_connection(connection_config)
        @sftp.download!(@remote_file_path, @tempfile.path)
        query = "SELECT * FROM read_csv_auto('#{@tempfile.path}')"
        records = db.query(query).columns
        catalog = Catalog.new(streams: create_streams(records.map(&:name)))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "SFTP:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      ensure
        @tempfile&.close!
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification
        connection_config = connection_config.with_indifferent_access
        conn = create_connection(connection_config)
        query = sync_config.model.query
        query = batched_query(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
        query(conn, query)
      rescue StandardError => e
        handle_exception(e, {
                           context: "SFTP:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def create_connection(connection_config)
        initialize_file_path(connection_config)
        @sftp = with_sftp_client(connection_config)
        conn = DuckDB::Database.open.connect
        conn.execute(INSTALL_HTTPFS_QUERY)
        conn
      end

      def initialize_file_path(connection_config)
        @remote_file_path = File.join(
          connection_config[:file_path],
          "#{connection_config[:file_name]}.#{connection_config[:format_type]}"
        )
        @tempfile = Tempfile.new(File.basename(@remote_file_path))
      end

      def with_sftp_client(connection_config, &block)
        Net::SFTP.start(
          connection_config[:host],
          connection_config[:username],
          password: connection_config[:password],
          port: connection_config.fetch(:port, 22), &block
        )
      end

      def get_results(conn, query)
        results = conn.query(query)
        hash_array_values(results)
      end

      def query(conn, query)
        query_regex = /\ASELECT\s+(?<columns>[\w,\s]+)\s+FROM\s+\w+\s*(?:LIMIT\s+(?<limit>\d+))?\s*(?:OFFSET\s+(?<offset>\d+))?\z/i
        match = query.match(query_regex)
        columns = match[:columns] || "*"
        offset = match[:offset].to_i || 0
        limit = match[:limit]&.to_i || nil
        @sftp.download!(@remote_file_path, @tempfile.path)
        adjusted_query = "SELECT #{columns} FROM read_csv_auto('#{@tempfile.path}') OFFSET #{offset}"
        adjusted_query += " LIMIT #{limit}" if limit
        records = get_results(conn, adjusted_query)
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

      def create_streams(records)
        group_by_table(records).map do |_, r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def group_by_table(records)
        result = {}
        records.each_with_index do |column, index|
          table_name = @remote_file_path
          column_data = {
            column_name: column,
            type: "string",
            optional: true
          }
          result[index] ||= {}
          result[index][:tablename] = table_name
          result[index][:columns] = [column_data]
        end
        result
      end
    end
  end
end
