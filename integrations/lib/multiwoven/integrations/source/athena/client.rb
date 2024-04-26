# frozen_string_literal: true

require "pg"

module Multiwoven::Integrations::Source
  module AWSAthena
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      rescue PG::Error => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
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
          "AWS:ATHENA:DISCOVER:EXCEPTION",
          "error",
          e
        )
      ensure
        db&.close
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification
        connection_config = connection_config.with_indifferent_access
        query = sync_config.model.query
        query = batched_query(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?

        db = create_connection(connection_config)

        query(db, query)
      rescue StandardError => e
        handle_exception(
          "AWS:ATHENA:READ:EXCEPTION",
          "error",
          e
        )
      ensure
        db&.close
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
        raise "Unsupported Auth type" unless connection_config[:credentials][:auth_type] == "access_key/secret_access_key"

        PG.connect(
          access_key: connection_config[:access_key],
          secret_access_key: connection_config[:secret_access_key],
          region: connection_config[:region],
          workgroup: connection_config[:workgroup],
          catalog: connection_config[:catalog],
          dbname: connection_config[:database],
          output_location: connection_config[:output_location]
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
    end
  end
end
