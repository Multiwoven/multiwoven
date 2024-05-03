# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module AmazonS3
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        client = config_aws(connection_config)
        client.head_object({
          bucket: connection_config[:bucket],
          key: connection_config[:file_key]
        })
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        client = config_aws(connection_config)
        options = build_select_content_options(connection_config, "SELECT * FROM S3Object LIMIT 1;")
        handler = Aws::S3::EventStreams::SelectObjectContentEventStream.new
        records = []
        handler.on_records_event do |event|
          records << JSON.parse(event.payload.read)
        end
        handler.on_end_event do |event|
          columns = records[0].keys.map do |key|
            {
              column_name: key
            }
          end
          streams = [Multiwoven::Integrations::Protocol::Stream.new(name: connection_config[:file_key], action: StreamAction["fetch"], json_schema: convert_to_json_schema(columns))]
          catalog = Catalog.new(streams: streams)
          catalog.to_multiwoven_message
        end
        handler.on_error_event do |event|
          raise event
        end
        options[:event_stream_handler] = handler
        client.select_object_content(options)
      rescue StandardError => e
        handle_exception("AMAZONS3:DISCOVER:EXCEPTION", "error", e)
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification.with_indifferent_access
        client = config_aws(connection_config)
        options = build_select_content_options(connection_config, sync_config.model.query)
        handler = Aws::S3::EventStreams::SelectObjectContentEventStream.new
        records = []
        handler.on_records_event do |event|
          records << JSON.parse(event.payload.read)
        end
        handler.on_end_event do |event|
          records.map do |row|
            RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
          end
        end
        handler.on_error_event do |event|
          raise event
        end
        options[:event_stream_handler] = handler
        client.select_object_content(options)
      rescue StandardError => e
        handle_exception("AMAZONS3:READ:EXCEPTION", "error", e)
      end

      private

      def config_aws(config)
        config = config.with_indifferent_access
        Aws.config.update({
          region: config[:region],
          credentials: Aws::Credentials.new(config[:access_id], config[:secret_access])
        })
        config = config.with_indifferent_access
        Aws::S3::Client.new
      end

      def build_select_content_options(config, query)
        config = config.with_indifferent_access
        bucket_name = config[:bucket]
        file_key = config[:file_key]
        file_type = config[:file_type]
        options = {
          bucket: bucket_name,
          key: file_key,
          expression_type: "SQL",
          expression: query,
          output_serialization: {
            json: {}
          }
        }
        if file_type == "parquet"
          options[:input_serialization] = {
            parquet: {}
          }
        elsif file_type == "csv"
          options[:input_serialization] = {
            csv: { file_header_info: "USE" }
          }
        end
        options
      end
    end
  end
end
