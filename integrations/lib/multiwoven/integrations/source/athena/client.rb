# frozen_string_literal: true

require "aws-sdk-athena"

module Multiwoven::Integrations::Source
  module AWSAthena
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.source.connection_specification
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
                 WHERE table_schema = '#{connection_config[:schema]}'
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

        db = create_connection(connection_config)
        response = db.start_query_execution({ query_string: "
            SELECT table_name, column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_schema = '#{connection_config[:schema]}'
            ORDER BY table_name, ordinal_position", result_configuration: { output_location: connection_config[:output_location] } })
        query_execution_id = response.query_execution_id
        db.get_query_execution({ query_execution_id: query_execution_id })
        sleep(5)

        results = db.get_query_results({ query_execution_id: query_execution_id })
        records = transform_query_results(results)
        query(records)
      rescue StandardError => e
        handle_exception(
          "AWS:ATHENA:READ:EXCEPTION",
          "error",
          e
        )
      end

      private

      def create_connection(connection_config)
        Aws.config.update({ credentials: Aws::Credentials.new(connection_config[:access_key], connection_config[:secret_access_key]), region: "us-east-2" })
        Aws::Athena::Client.new
      end

      def create_streams(records)
        group_by_table(records).map do |r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def transform_query_results(query_results)
        return [] if query_results.nil? || query_results.result_set.nil? || query_results.result_set.rows.nil?

        columns = query_results.result_set.result_set_metadata.column_info
        rows = query_results.result_set.rows

        records = rows.map do |row|
          data = row.data
          columns.map.with_index do |column, index|
            [column.name, data[index].var_char_value]
          end.to_h
        end

        group_by_table(records)
      end

      def query(queries)
        records = []
        queries.map do |row|
          records << RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
        records
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
