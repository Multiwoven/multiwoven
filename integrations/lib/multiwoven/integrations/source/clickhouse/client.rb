# frozen_string_literal: true

require "clickhouse"
require "faraday"

module Multiwoven::Integrations::Source
  module ClickHouse
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
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
        byebug
        response = connection.post('/query') do |req|
            req.body = { query: query }.to_json
        end
        w = connection.query(query)
        byebug
        connection.get(query) do |result|
          byebug
          result.map do |row|
            RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
          end
        end
      end

      def create_connection(connection_config)
        #raise "Unsupported Auth type" unless connection_config[:credentials][:auth_type] == "username/password"
        #connection = Faraday.new(url: connection_config[:host]) do |faraday|
          #faraday.request :authorization, :basic, connection_config[:username], connection_config[:password]
          #faraday.adapter :net_http
        #end
        byebug

        #conn = Faraday.new(url: connection_config[:host], headers: {'Content-Type' => 'application/json'}) do |faraday|
          #faraday.request :url_encoded
          #faraday.adapter Faraday.default_adapter
        #end

        #response = conn.get "/"

        # Create a connection
        client = Clickhouse::Client.new(
          url: 'http://localhost:8123', # URL of your ClickHouse server
          username: 'your_username',    # Username for authentication
          password: 'your_password'     # Password for authentication
        )
        client
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
