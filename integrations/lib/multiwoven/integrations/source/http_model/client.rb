# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module HttpModel
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = prepare_config(connection_config)
        response = send_request(
          url: connection_config[:url_host],
          http_method: connection_config[:http_method],
          payload: JSON.parse(connection_config[:request_format]),
          headers: connection_config[:headers],
          config: connection_config[:config]
        )
        success?(response) ? success_status : failure_status(nil)
      rescue StandardError => e
        handle_exception(e, { context: "HTTP MODEL:CHECK_CONNECTION:EXCEPTION", type: "error" })
        failure_status(e)
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, { context: "HTTP MODEL:DISCOVER:EXCEPTION", type: "error" })
      end

      def read(sync_config)
        connection_config = prepare_config(sync_config.source.connection_specification)
        stream = connection_config[:is_stream] ||= false
        # The server checks the ConnectorQueryType.
        # If it's "ai_ml," the server calculates the payload and passes it as a query in the sync config model protocol.
        # This query is then sent to the AI/ML model.
        payload = parse_json(sync_config.model.query)

        if stream
          run_model_stream(connection_config, payload) { |message| yield message if block_given? }
        else
          run_model(connection_config, payload)
        end
      rescue StandardError => e
        handle_exception(e, { context: "HTTP MODEL:READ:EXCEPTION", type: "error" })
      end

      private

      def prepare_config(config)
        config.with_indifferent_access.tap do |conf|
          conf[:config][:timeout] ||= 30
        end
      end

      def parse_json(json_string)
        JSON.parse(json_string)
      rescue JSON::ParserError => e
        handle_exception(e, { context: "HTTP MODEL:PARSE_JSON:EXCEPTION", type: "error" })
        {}
      end

      def run_model(connection_config, payload)
        response = send_request(
          url: connection_config[:url_host],
          http_method: connection_config[:http_method],
          payload: payload,
          headers: connection_config[:headers],
          config: connection_config[:config]
        )
        process_response(response)
      rescue StandardError => e
        handle_exception(e, { context: "HTTP MODEL:RUN_MODEL:EXCEPTION", type: "error" })
      end

      def run_model_stream(connection_config, payload)
        send_streaming_request(
          url: connection_config[:url_host],
          http_method: connection_config[:http_method],
          payload: payload,
          headers: connection_config[:headers],
          config: connection_config[:config]
        ) do |chunk|
          process_streaming_response(chunk) { |message| yield message if block_given? }
        end
      rescue StandardError => e
        handle_exception(e, { context: "HTTP MODEL:RUN_STREAM_MODEL:EXCEPTION", type: "error" })
      end

      def process_response(response)
        if success?(response)
          data = JSON.parse(response.body)
          [RecordMessage.new(data: data, emitted_at: Time.now.to_i).to_multiwoven_message]
        else
          create_log_message("HTTP MODEL:RUN_MODEL", "error", "request failed: #{response.body}")
        end
      rescue StandardError => e
        handle_exception(e, { context: "HTTP MODEL:PROCESS_RESPONSE:EXCEPTION", type: "error" })
      end

      def process_streaming_response(chunk)
        data = JSON.parse(chunk)
        yield [RecordMessage.new(data: data, emitted_at: Time.now.to_i).to_multiwoven_message] if block_given?
      rescue StandardError => e
        handle_exception(e, { context: "HTTP MODEL:PROCESS_STREAMING_RESPONSE:EXCEPTION", type: "error" })
      end
    end
  end
end
