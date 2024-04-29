# frozen_string_literal: true

require "aws-sdk-athena"

module Multiwoven::Integrations::Source
  module AWSAthena
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        query = "SELECT table_name, column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema = '#{connection_config[:schema]}' ORDER BY table_name, ordinal_position;"

        db = create_connection(connection_config)
        response = db.start_query_execution(
          query_string: query,
          result_configuration: { output_location: connection_config[:output_location] }
        )
        query_execution_id = response[:query_execution_id]
        # Polling for query execution completion
        db.get_query_execution(query_execution_id: query_execution_id)

        results = db.get_query_results(query_execution_id: query_execution_id)
        records = transform_records(results)
        catalog = Catalog.new(streams: create_streams(records))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(
          "AWS:ATHENA:DISCOVER:EXCEPTION",
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
        response = db.start_query_execution(
          query_string: query,
          result_configuration: { output_location: sync_config[:source][:connection_specification][:output_location] }
        )
        query_execution_id = response[:query_execution_id]
        db.get_query_execution({ query_execution_id: query_execution_id })

        results = db.get_query_results({ query_execution_id: query_execution_id })
        query(results[:ResultSet])
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
        group_by_table(records).map do |_, r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def transform_records(records)
        result = records[:ResultSet].map do |row|
          data = row[:Data].map { |item| item[:VarCharValue] }
          {
            table_name: data[0],
            column_name: data[1],
            data_type: data[2],
            is_nullable: data[3] == "YES"
          }
        end
        { ResultSet: result }
      end

      def query(queries)
        records = []
        queries.map do |row|
          records << RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
        records
      end

      def group_by_table(records)
        result = {}
        records[:ResultSet].each_with_index do |entry, index|
          table_name = entry[:table_name]
          column_data = {
            column_name: entry[:column_name],
            data_type: entry[:data_type],
            is_nullable: entry[:is_nullable]
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
