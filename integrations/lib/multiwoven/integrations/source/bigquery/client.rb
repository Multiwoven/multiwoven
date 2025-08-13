# frozen_string_literal: true

require "google/cloud/bigquery"

module Multiwoven::Integrations::Source
  module Bigquery
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        bigquery = create_connection(connection_config)
        bigquery.datasets
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        bigquery = create_connection(connection_config)
        target_dataset_id = connection_config["dataset_id"]
        records = bigquery.datasets.flat_map do |dataset|
          next unless dataset.dataset_id == target_dataset_id

          dataset.tables.flat_map do |table|
            table.schema.fields.map do |field|
              {
                table_name: table.table_id,
                column_name: field.name,
                data_type: field.type,
                is_nullable: field.mode == "NULLABLE"
              }
            end
          end
        end
        catalog = Catalog.new(streams: create_streams(records))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "BIGQUERY:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification
        connection_config = connection_config.with_indifferent_access
        query = sync_config.model.query

        query = batched_query(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?

        bigquery = create_connection(connection_config)

        query(bigquery, query)
      rescue StandardError => e
        handle_exception(e, {
                           context: "BIGQUERY:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def query(connection, query)
        records = []
        results = connection.query(query) || []
        results.each do |row|
          records << RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
        records
      end

      def create_connection(connection_config)
        credentials = connection_config["credentials_json"]

        credentials["private_key"] = credentials["private_key"].gsub("\\n", "\n") if credentials["private_key"].include?("\\n")

        Google::Cloud::Bigquery.new(
          project: connection_config["project_id"],
          credentials: connection_config["credentials_json"]
        )
      end

      def create_streams(records)
        group_by_table(records).map do |r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def group_by_table(records)
        records.group_by { |entry| entry[:table_name] }.map do |table_name, columns|
          {
            tablename: table_name,
            columns: columns.map { |column| { column_name: column[:column_name], type: column[:data_type], optional: column[:is_nullable] == "YES" } }
          }
        end
      end
    end
  end
end
