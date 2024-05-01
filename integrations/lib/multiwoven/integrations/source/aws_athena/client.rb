# frozen_string_literal: true

require "aws-sdk-athena"

module Multiwoven::Integrations::Source
  module AWSAthena
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        athena_client = create_connection(connection_config)
        athena_client.list_work_groups
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
          query_execution_context: { database: connection_config[:schema] },
          result_configuration: { output_location: connection_config[:output_location] }
        )
        query_execution_id = response[:query_execution_id]
        wait_for_query_completion(db, query_execution_id)

        results = transform_results(db.get_query_results(query_execution_id: query_execution_id))
        catalog = Catalog.new(streams: create_streams(results))
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
          query_execution_context: { database: sync_config[:source][:connection_specification][:schema] },
          result_configuration: { output_location: sync_config[:source][:connection_specification][:output_location] }
        )
        query_execution_id = response[:query_execution_id]
        wait_for_query_completion(db, query_execution_id)
        results = transform_results(db.get_query_results(query_execution_id: query_execution_id))
        query(results)
      rescue StandardError => e
        handle_exception(
          "AWS:ATHENA:READ:EXCEPTION",
          "error",
          e
        )
      end

      private

      def create_connection(connection_config)
        Aws.config.update({ credentials: Aws::Credentials.new(connection_config[:access_key], connection_config[:secret_access_key]), region: connection_config[:region] })
        Aws::Athena::Client.new
      end

      def create_streams(records)
        group_by_table(records).map do |_, r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def wait_for_query_completion(db, query_execution_id)
        loop do
          response = db.get_query_execution(query_execution_id: query_execution_id)
          status = response.query_execution.status.state
          break if %w[SUCCEEDED FAILED CANCELLED].include?(status)

          sleep 1
        end
      end

      def transform_results(results)
        columns = results.result_set.result_set_metadata.column_info.map(&:name)
        rows = results.result_set.rows.map do |row|
          row.data.map(&:var_char_value)
        end
        rows.map { |row| columns.zip(row).to_h }
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
        records.each_with_index do |entry, index|
          table_name = entry["table_name"]
          column_data = {
            column_name: entry["column_name"],
            data_type: entry["data_type"],
            is_nullable: entry["is_nullable"] == "YES"
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
