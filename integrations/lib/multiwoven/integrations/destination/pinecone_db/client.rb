# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module PineconeDB
    include Multiwoven::Integrations::Core
    PINECONE_OBJECTS = [
      { column_name: "id", data_type: "string", is_nullable: false },
      { column_name: "value", data_type: "vector", is_nullable: false },
      { column_name: "meta_data", data_type: "string", is_nullable: false }
    ].freeze
    class Client < DestinationConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        result = @pinecone.describe_index(@index_name)
        if result
          success_status
        else
          failure_status(nil)
        end
      rescue StandardError => e
        handle_exception(e, { context: "PINECONE:CHECK_CONNECTION:EXCEPTION", type: "error" })
        failure_status(e)
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        pinecone_index = @pinecone.index(@index_name)
        response = pinecone_index.describe_index_stats
        results = JSON.parse(response.body)
        records = results["namespaces"].keys
        catalog = Catalog.new(streams: create_streams(records))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "PINECONE:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def write(sync_config, records, _action = "upsert")
        @sync_config = sync_config
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        create_connection(connection_config)
        process_records(records, sync_config.stream)
      rescue StandardError => e
        handle_exception(e, {
                           context: "PINECONE:WRITE:EXCEPTION",
                           type: "error",
                           sync_id: @sync_config.sync_id,
                           sync_run_id: @sync_config.sync_run_id
                         })
      end

      private

      def create_connection(connection_config)
        initialize_client(connection_config)
        Pinecone.configure do |config|
          config.api_key = @api_key
          config.environment = @region
        end
        @pinecone = Pinecone::Client.new
      end

      def initialize_client(connection_config)
        @api_key = connection_config["api_key"]
        @region = connection_config["region"]
        @index_name = connection_config["index_name"]
      end

      def process_records(records, stream)
        log_message_array = []
        write_success = 0
        write_failure = 0
        properties = stream.json_schema[:properties]

        records.each do |record_object|
          record = extract_data(record_object, properties)
          @namespace = stream.name
          args = [@index_name, @namespace, record]
          begin
            pinecone_index = @pinecone.index(@index_name)
            response = send_to_pinecone(pinecone_index, record)
            if success?(response)
              write_success += 1
            else
              write_failure += 1
            end
            log_message_array << log_request_response("info", args, response)
          rescue StandardError => e
            handle_exception(e, {
                               context: "PINECONE:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: @sync_config.sync_id,
                               sync_run_id: @sync_config.sync_run_id
                             })
            write_failure += 1
            log_message_array << log_request_response("error", args, e.message)
          end
        end
        tracking_message(write_success, write_failure, log_message_array)
      end

      def parse_meta_data(vector_meta_data)
        return {} if vector_meta_data.nil?

        metadata = vector_meta_data.to_s
        metadata = metadata.gsub(/([{,]\s*)([A-Za-z_]\w*)(\s*:)/, '\1"\2"\3')
        metadata = metadata.gsub(/:\s*([A-Za-z_]\w*)/, ': "\1"')

        JSON.parse(metadata)
      rescue JSON::ParserError
        {}
      end

      def send_to_pinecone(pinecone_index, record)
        meta_data = parse_meta_data(record[:meta_data])
        pinecone_index.upsert(
          namespace: @namespace,
          vectors: [
            {
              id: record[:id].to_s,
              values: record[:value],
              metadata: meta_data
            }
          ]
        )
      end

      def create_streams(records)
        group_by_table(records).map do |r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["create"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def group_by_table(records)
        records.map do |table_name|
          {
            tablename: table_name,
            columns: PINECONE_OBJECTS.map do |column|
              {
                column_name: column[:column_name],
                type: column[:data_type],
                optional: column[:is_nullable]
              }
            end
          }
        end
      end
    end
  end
end
