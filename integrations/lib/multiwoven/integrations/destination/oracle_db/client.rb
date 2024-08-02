# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module Oracle
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        ConnectionStatus.new(
          status: ConnectionStatusType["succeeded"]
        ).to_multiwoven_message
      rescue StandardError => e
        ConnectionStatus.new(
          status: ConnectionStatusType["failed"], message: e.message
        ).to_multiwoven_message
      end

      def discover(connection_config)
        records = []
        connection_config = connection_config.with_indifferent_access
        query = "SELECT table_name, column_name, data_type, nullable
                 FROM all_tab_columns
                 WHERE owner = '#{connection_config[:username].upcase}'
                 ORDER BY table_name, column_id"
        conn = create_connection(connection_config)
        cursor = conn.exec(query)
        while (row = cursor.fetch)
          records << row
        end
        catalog = Catalog.new(streams: create_streams(records))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(
          "ORACLE:DISCOVER:EXCEPTION",
          "error",
          e
        )
      end

      def write(sync_config, records, action = "destination_insert")
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        table_name = sync_config.stream.name
        primary_key = sync_config.model.primary_key
        conn = create_connection(connection_config)

        write_success = 0
        write_failure = 0
        log_message_array = []

        records.each do |record|
          query = Multiwoven::Integrations::Core::QueryBuilder.perform(action, table_name, record, primary_key)
          query = query.gsub(";", "")
          logger.debug("ORACLE:WRITE:QUERY query = #{query} sync_id = #{sync_config.sync_id} sync_run_id = #{sync_config.sync_run_id}")
          begin
            response = conn.exec(query)
            conn.exec("COMMIT")
            write_success += 1
            log_message_array << log_request_response("info", query, response)
          rescue StandardError => e
            handle_exception(e, {
                               context: "ORACLE:RECORD:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: sync_config.sync_id,
                               sync_run_id: sync_config.sync_run_id
                             })
            write_failure += 1
            log_message_array << log_request_response("error", query, e.message)
          end
        end
        tracking_message(write_success, write_failure, log_message_array)
      rescue StandardError => e
        handle_exception(e, {
                           context: "ORACLE:RECORD:WRITE:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def create_connection(connection_config)
        OCI8.new(connection_config[:username], connection_config[:password], "#{connection_config[:host]}:#{connection_config[:port]}/#{connection_config[:sid]}")
      end

      def create_streams(records)
        group_by_table(records).map do |_, r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def group_by_table(records)
        result = {}
        records.each_with_index do |entry, index|
          table_name = entry[0]
          column_data = {
            column_name: entry[1],
            data_type: entry[2],
            is_nullable: entry[3] == "Y"
          }
          result[index] ||= {}
          result[index][:tablename] = table_name
          result[index][:columns] = [column_data]
        end
        result.values.group_by { |entry| entry[:tablename] }.transform_values do |entries|
          { tablename: entries.first[:tablename], columns: entries.flat_map { |entry| entry[:columns] } }
        end
      end
    end
  end
end
