# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Oracle
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
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

      def read(sync_config)
        connection_config = sync_config.source.connection_specification.with_indifferent_access
        query = sync_config.model.query
        db = create_connection(connection_config)
        query(db, query)
      rescue StandardError => e
        handle_exception(e, {
                           context: "ORACLE:READ:EXCEPTION",
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

      def query(connection, query)
        records = []
        query = reformat_query(query)
        cursor = connection.exec(query)
        columns = cursor.get_col_names
        while (row = cursor.fetch)
          data_hash = columns.zip(row).to_h
          records << RecordMessage.new(data: data_hash, emitted_at: Time.now.to_i).to_multiwoven_message
        end
        records
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

      def reformat_query(sql_query)
        offset = nil
        limit = nil

        sql_query = sql_query.gsub(";", "")

        if sql_query.match?(/LIMIT (\d+)/i)
          limit = sql_query.match(/LIMIT (\d+)/i)[1].to_i
          sql_query.sub!(/LIMIT \d+/i, "")
        end

        if sql_query.match?(/OFFSET (\d+)/i)
          offset = sql_query.match(/OFFSET (\d+)/i)[1].to_i
          sql_query.sub!(/OFFSET \d+/i, "")
        end

        sql_query.strip!

        if offset && limit
          "#{sql_query} OFFSET #{offset} ROWS FETCH NEXT #{limit} ROWS ONLY"
        elsif offset
          "#{sql_query} OFFSET #{offset} ROWS"
        elsif limit
          "#{sql_query} FETCH NEXT #{limit} ROWS ONLY"
        else
          sql_query
        end
      end
    end
  end
end
