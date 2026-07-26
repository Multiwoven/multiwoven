# frozen_string_literal: true

require "pg"

module Multiwoven::Integrations::Destination
  module Postgresql
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      MAX_CHUNK_SIZE = 10_000

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
        query = "SELECT table_name, column_name,
                 CASE WHEN data_type = 'USER-DEFINED' THEN udt_name ELSE data_type END
                 AS data_type,
                 is_nullable
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
        handle_exception(e, {
                           context: "POSTGRESQL:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      ensure
        db&.close
      end

      def write(sync_config, records, action = "destination_insert", identifier_key = nil)
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        raw_table = sync_config.stream.name
        table_name = qualify_table(connection_config[:schema], raw_table)
        primary_key = sync_config.model.primary_key
        db = create_connection(connection_config)
<<<<<<< HEAD
=======
        primary_key = fetch_primary_key(db, connection_config[:schema], raw_table)
        opts = { action: action, identifier_key: identifier_key, sync_config: sync_config }
>>>>>>> d9813065c (fix(CE): Added a record indentifier for batch support (#1885))

        write_success = 0
        write_failure = 0
        log_message_array = []

        records.each_slice(MAX_CHUNK_SIZE) do |chunk|
          bulk_write(db, table_name, chunk, primary_key, opts)
          write_success += chunk.size
          log_message_array << log_request_response("info", "bulk_#{action}", "#{chunk.size} rows")
        rescue StandardError => e
          logger.warn("POSTGRESQL:BULK_WRITE:FALLBACK chunk_size=#{chunk.size} error=#{e.message}")
          success, failure, logs = write_chunk_fallback(db, table_name, chunk, primary_key, opts)
          write_success += success
          write_failure += failure
          log_message_array.concat(logs)
        end

        tracking_message(write_success, write_failure, log_message_array)
      rescue StandardError => e
        handle_exception(e, {
                           context: "POSTGRESQL:RECORD:WRITE:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      ensure
        db&.close
      end

      private

      def write_chunk_fallback(db, table_name, chunk, primary_key, opts)
        action = opts[:action]
        identifier_key = opts[:identifier_key]
        sync_config = opts[:sync_config]
        success = 0
        failure = 0
        logs = []

        chunk.each do |record|
          response = bulk_write(db, table_name, [record], primary_key, opts)
          success += 1
          logs << log_request_response("info", "fallback_#{action}", response, record[identifier_key])
        rescue StandardError => individual_error # rubocop:disable Naming/RescuedExceptionsVariableName
          handle_exception(individual_error, {
                             context: "POSTGRESQL:RECORD:WRITE:EXCEPTION",
                             type: "error",
                             sync_id: sync_config.sync_id,
                             sync_run_id: sync_config.sync_run_id
                           })
          failure += 1
          logs << log_request_response("error", "fallback_#{action}", individual_error.message, record[identifier_key])
        end

        [success, failure, logs]
      end

      def bulk_write(db, table_name, records, primary_key, opts)
        action = opts[:action]
        identifier_key = opts[:identifier_key]
        return if records.empty?

        columns = records.flat_map(&:keys).uniq
        columns -= [identifier_key] if identifier_key
        col_list = columns.map { |c| quote_ident(c) }.join(", ")

        values_clauses = records.map do |record|
          vals = columns.map { |col| escape_value(db, record[col]) }
          "(#{vals.join(", ")})"
        end

<<<<<<< HEAD
        sql = "INSERT INTO #{table_name} (#{col_list}) VALUES #{values_clauses.join(", ")}"
        sql += build_upsert_clause(columns, primary_key) if action.to_s == "destination_update"
        db.exec(sql)
=======
        conflict = build_conflict_clause(primary_key, action, columns)
        db.exec("INSERT INTO #{table_name} (#{col_list}) VALUES #{values_clauses.join(", ")}#{conflict}")
      end

      def build_conflict_clause(primary_key, action, columns)
        return "" unless primary_key.present?

        action.to_s == "destination_insert" ? build_safe_insert_clause(primary_key) : build_upsert_clause(columns, primary_key)
>>>>>>> d9813065c (fix(CE): Added a record indentifier for batch support (#1885))
      end

      def build_upsert_clause(columns, primary_key)
        return "" unless primary_key.present?

        update_cols = columns.reject { |c| c.to_s == primary_key.to_s }
        return " ON CONFLICT (#{quote_ident(primary_key)}) DO NOTHING" if update_cols.empty?

        set_clause = update_cols.map { |c| "#{quote_ident(c)} = EXCLUDED.#{quote_ident(c)}" }.join(", ")
        " ON CONFLICT (#{quote_ident(primary_key)}) DO UPDATE SET #{set_clause}"
      end

      def escape_value(db, value)
        return "NULL" if value.nil?

        "'#{db.escape_string(value.to_s)}'"
      end

      def quote_ident(name)
        PG::Connection.quote_ident(name.to_s)
      end

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
          Multiwoven::Integrations::Protocol::Stream.new(
            name: r[:tablename],
            action: StreamAction["fetch"],
            json_schema: convert_to_json_schema(r[:columns]),
            batch_support: true,
            batch_size: MAX_CHUNK_SIZE
          )
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

      def qualify_table(schema, table)
        return table if schema.blank? || schema == "public"

        %("#{schema}"."#{table}")
      end
    end
  end
end
