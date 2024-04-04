# frozen_string_literal: true

require "pg"

module Multiwoven::Integrations::Destination
  module Postgresql
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        ConnectionStatus.new(
          status: ConnectionStatusType["succeeded"]
        ).to_multiwoven_message
      rescue PG::Error => e
        ConnectionStatus.new(
          status: ConnectionStatusType["failed"], message: e.message
        ).to_multiwoven_message
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        query = "SELECT table_name, column_name, data_type, is_nullable
                 FROM information_schema.columns
                 WHERE table_schema = '#{connection_config[:schema]}' AND table_catalog = '#{connection_config[:database]}'
                 ORDER BY table_name, ordinal_position;"

        db = create_connection(connection_config)
        records = db.exec(query) do |result|
          result.map do |row|
            row
          end
        end
        catalog = Catalog.new(streams: create_streams(records))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(
          "POSTGRESQL:DISCOVER:EXCEPTION",
          "error",
          e
        )
      ensure
        db&.close
      end

      def write(sync_config, records, action = "insert")
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        table_name = sync_config.stream.name
        db = create_connection(connection_config)

        write_success = 0
        write_failure = 0

        records.each do |record|
          query = Multiwoven::Integrations::Core::QueryBuilder.perform(action, table_name, record)
          begin
            db.exec(query)
            write_success += 1
          rescue StandardError => e
            handle_exception("POSTGRESQL:RECORD:WRITE:EXCEPTION", "error", e)
            write_failure += 1
          end
        end
        tracking_message(write_success, write_failure)
      rescue StandardError => e
        handle_exception(
          "POSTGRESQL:WRITE:EXCEPTION",
          "error",
          e
        )
      end

      private

      def query(connection, query)
        connection.exec(query) do |result|
          result.map do |row|
            RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
          end
        end
      end

      def create_connection(connection_config)
        raise "Unsupported Auth type" unless connection_config[:credentials][:auth_type] == "username/password"

        PG.connect(
          host: connection_config[:host],
          dbname: connection_config[:database],
          user: connection_config[:credentials][:username],
          password: connection_config[:credentials][:password],
          port: connection_config[:port]
        )
      end

      def create_streams(records)
        group_by_table(records).map do |r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def group_by_table(records)
        records.group_by { |entry| entry["table_name"] }.map do |table_name, columns|
          {
            tablename: table_name,
            columns: columns.map do |column|
              {
                column_name: column["column_name"],
                type: column["data_type"],
                optional: column["is_nullable"] == "YES"
              }
            end
          }
        end
      end

      def tracking_message(success, failure)
        Multiwoven::Integrations::Protocol::TrackingMessage.new(
          success: success, failed: failure
        ).to_multiwoven_message
      end
    end
  end
end
