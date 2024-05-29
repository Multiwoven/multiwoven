# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Clickhouse
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
        connection_config = connection_config.with_indifferent_access
        query = "SELECT table_name, column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema = '#{connection_config[:database]}' ORDER BY table_name, ordinal_position;"
        db = create_connection(connection_config)
        records = query_execution(db, query)
        catalog = Catalog.new(streams: create_streams(records))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(
          "CLICKHOUSE:DISCOVER:EXCEPTION",
          "error",
          e
        )
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
          "CLICKHOUSE:READ:EXCEPTION",
          "error",
          e
        )
      end

      private

      def query(connection, query)
        query_execution(connection, query).map do |row|
          RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      def create_connection(connection_config)
        @auth_token = Base64.strict_encode64("#{connection_config[:username]}:#{connection_config[:password]}")
        Faraday.new(connection_config[:host]) do |faraday|
          faraday.request :url_encoded
          faraday.adapter Faraday.default_adapter
        end
      end

      def query_execution(connection, query)
        response = connection.post do |req|
          req.url "/"
          req.headers["Authorization"] = "Basic #{@auth_token}"
          req.headers["Content-Type"] = "text/plain"
          req.body = query
        end
        column_names = query[/SELECT (.*?) FROM/i, 1].split(",").map(&:strip)
        response.body.strip.split("\n").map do |row|
          columns = row.split("\t")
          column_names.zip(columns).to_h
        end
      end

      def create_streams(records)
        group_by_table(records).map do |_, r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def group_by_table(records)
        result = {}
        records.each_with_index do |entry, index|
          table_name = entry["table_name"]
          column_data = {
            column_name: entry["column_name"],
            data_type: entry["data_type"].gsub(/Nullable\((\w+)\)/, '\1').downcase.gsub!(/\d+/, ""),
            is_nullable: entry["is_nullable"] == "1"
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
