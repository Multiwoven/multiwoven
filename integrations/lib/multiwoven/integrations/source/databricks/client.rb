# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Databricks
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      rescue Sequel::DatabaseConnectionError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        query = "SELECT table_name, column_name, data_type, is_nullable
                FROM system.information_schema.columns
                WHERE table_schema = \'#{connection_config[:schema]}\' AND table_catalog = \'#{connection_config[:catalog]}\'
                ORDER BY table_name, ordinal_position;"

        db = create_connection(connection_config)

        records = []
        db.fetch(query.gsub("\n", "")) do |row|
          records << row
        end
        catalog = Catalog.new(streams: create_streams(records))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "DATABRICKS:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification
        connection_config = connection_config.with_indifferent_access
        query = sync_config.model.query
        query = batched_query(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?

        db = create_connection(connection_config)

        query(db, query)
      rescue StandardError => e
        handle_exception(e, {
                           context: "DATABRICKS:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def query(connection, query)
        records = []
        connection.fetch(query) do |row|
          records << RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
        records
      end

      def create_connection(connection_config)
        Sequel.odbc(drvconnect: generate_drvconnect(connection_config))
      end

      def generate_drvconnect(connection_config)
        "Driver=#{DATABRICKS_DRIVER_PATH};
        Host=#{connection_config[:host]};
        PORT=#{connection_config[:port]};
        SSL=1;
        HTTPPath=#{connection_config[:http_path]};
        PWD=#{connection_config[:access_token]};
        UID=token;
        ThriftTransport=2;AuthMech=3;
        AllowSelfSignedServerCert=1;
        CAIssuedCertNamesMismatch=1"
      end

      def create_streams(records)
        group_by_table(records).map do |r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def group_by_table(records)
        records.group_by { |entry| entry[:table_name] }.map do |table_name, columns|
          {
            tablename: table_name,
            columns: columns.map { |column| { column_name: column[:column_name], type: column[:data_type], optional: column[:is_nullable] == "YES" } }
          }
        end
      end
    end
  end
end
