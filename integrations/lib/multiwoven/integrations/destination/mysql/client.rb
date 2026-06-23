# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module Mysql
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        db = create_connection(connection_config)
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      ensure
        db&.disconnect
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        db = create_connection(connection_config)
        query = "SELECT table_name, column_name, data_type, is_nullable
                 FROM information_schema.columns
                 WHERE table_schema = ?
                 ORDER BY table_name, ordinal_position;"
        records = db.fetch(query, connection_config[:database]).all.map { |row| row.transform_keys { |k| k.to_s.downcase.to_sym } }
        catalog = Catalog.new(streams: create_streams(records))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "MYSQL:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      ensure
        db&.disconnect
      end

      def write(sync_config, records, action = "destination_insert")
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        table_name = sync_config.stream.name
        primary_key = sync_config.model.primary_key
        db = create_connection(connection_config)

        log_message_array = []
        write_success = 0
        write_failure = 0

        records.each do |record|
          query = Multiwoven::Integrations::Core::QueryBuilder.perform(action, table_name, record, primary_key)
          logger.debug("MYSQL:WRITE:QUERY action = #{action} table_name = #{table_name} primary_key = #{primary_key} sync_id = #{sync_config.sync_id} sync_run_id = #{sync_config.sync_run_id}")
          begin
            db.run(query)
            write_success += 1
            log_message_array << log_request_response("info", "#{action} #{table_name}", "Successful")
          rescue StandardError => e
            handle_exception(e, {
                               context: "MYSQL:RECORD:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: sync_config.sync_id,
                               sync_run_id: sync_config.sync_run_id
                             })
            write_failure += 1
            log_message_array << log_request_response("error", "#{action} #{table_name}", e.message)
          end
        end
        tracking_message(write_success, write_failure, log_message_array)
      rescue StandardError => e
        handle_exception(e, {
                           context: "MYSQL:WRITE:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      ensure
        db&.disconnect
      end

      private

      def create_connection(connection_config)
        Sequel.connect(
          adapter: "mysql2",
          host: connection_config[:host],
          port: connection_config[:port],
          user: connection_config[:username],
          password: connection_config[:password],
          database: connection_config[:database]
        )
      end

      def create_streams(records)
        group_by_table(records).map do |_, r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def group_by_table(records)
        result = {}
        records.each do |entry|
          table_name = entry[:table_name]
          column_data = {
            column_name: entry[:column_name],
            data_type: entry[:data_type],
            is_nullable: entry[:is_nullable] == "YES"
          }
          result[table_name] ||= { tablename: table_name, columns: [] }
          result[table_name][:columns] << column_data
        end
        result
      end
    end
  end
end
