# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Destination
      module DatabricksLakehouse
        include Multiwoven::Integrations::Core
        class Client < DestinationConnector
          MAX_CHUNK_SIZE = 10
          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            db = create_connection(connection_config)
            response = db.get("/api/2.0/clusters/list")
            if response.status == 200
              success_status
            else
              failure_status(nil)
            end
          rescue StandardError => e
            handle_exception(e, {
                               context: "DATABRICKS:LAKEHOUSE:CHECK_CONNECTION:EXCEPTION",
                               type: "error"
                             })
            failure_status(e)
          end

          def discover(connection_config)
            connection_config = connection_config.with_indifferent_access
            table_query = "SHOW TABLES IN #{connection_config[:catalog]}.#{connection_config[:schema]};"
            db = create_connection(connection_config)
            records = []
            table_response = db.post("/api/2.0/sql/statements", generate_body(connection_config[:warehouse_id], table_query).to_json)
            table_response_body = JSON.parse(table_response.body)
            table_response_body["result"]["data_array"].each do |table|
              table_name = table[1]
              query = "DESCRIBE TABLE #{connection_config[:catalog]}.#{connection_config[:schema]}.#{table_name};"
              column_response = db.post("/api/2.0/sql/statements", generate_body(connection_config[:warehouse_id], query).to_json)
              column_response_body = JSON.parse(column_response.body)
              records << [table_name, column_response_body["result"]["data_array"]]
            end
            catalog = Catalog.new(streams: create_streams(records))
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception(
              "DATABRICKS:LAKEHOUSE:DISCOVER:EXCEPTION",
              "error",
              e
            )
          end

          def write(sync_config, records, action = "destination_insert")
            connection_config = sync_config.destination.connection_specification.with_indifferent_access
            table_name = "#{connection_config[:catalog]}.#{connection_config[:schema]}.#{sync_config.stream.name}"
            primary_key = sync_config.model.primary_key
            db = create_connection(connection_config)
            write_success = 0
            write_failure = 0
            log_message_array = []

            records.each do |record|
              query = Multiwoven::Integrations::Core::QueryBuilder.perform(action, table_name, record, primary_key)
              logger.debug("DATABRICKS:LAKEHOUSE:WRITE:QUERY query = #{query} sync_id = #{sync_config.sync_id} sync_run_id = #{sync_config.sync_run_id}")
              begin
                arg = ["/api/2.0/sql/statements", generate_body(connection_config[:warehouse_id], query)]
                response = db.post("/api/2.0/sql/statements", generate_body(connection_config[:warehouse_id], query).to_json)
                if response.status == 200
                  write_success += 1
                else
                  write_failure += 1
                end
                log_message_array << log_request_response("info", arg, response)
              rescue StandardError => e
                handle_exception(e, {
                                   context: "DATABRICKS:LAKEHOUSE:RECORD:WRITE:EXCEPTION",
                                   type: "error",
                                   sync_id: sync_config.sync_id,
                                   sync_run_id: sync_config.sync_run_id
                                 })
                write_failure += 1
              end
            end
            tracking_message(write_success, write_failure)
          rescue StandardError => e
            handle_exception(e, {
                               context: "DATABRICKS:LAKEHOUSE:RECORD:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: sync_config.sync_id,
                               sync_run_id: sync_config.sync_run_id
                             })
          end

          private

          def create_connection(connection_config)
            Faraday.new(url: connection_config[:host]) do |conn|
              conn.headers["Authorization"] = "Bearer #{connection_config[:api_token]}"
              conn.headers["Content-Type"] = "application/json"
              conn.adapter Faraday.default_adapter
            end
          end

          def generate_body(warehouse_id, query)
            {
              warehouse_id: warehouse_id,
              statement: query,
              wait_timeout: "15s"
            }
          end

          def create_streams(records)
            message = []
            group_by_table(records).each_value do |r|
              message << Multiwoven::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
            end
            message
          end

          def group_by_table(records)
            result = {}
            records.each_with_index do |entries, index|
              table_name = records[index][0]
              column = []
              entry_data = entries[1]
              entry_data.each do |entry|
                column << {
                  column_name: entry[0],
                  data_type: entry[1],
                  is_nullable: true
                }
              end
              result[index] ||= {}
              result[index][:tablename] = table_name
              result[index][:columns] = column
            end
            result
          end

          def tracking_message(success, failure)
            Multiwoven::Integrations::Protocol::TrackingMessage.new(
              success: success, failed: failure
            ).to_multiwoven_message
          end
        end
      end
    end
  end
end
