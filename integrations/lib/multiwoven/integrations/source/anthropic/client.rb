# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Anthropic
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      API_VERSION = "2023-06-01"
      def check_connection(connection_config)
        connection_config = prepare_config(connection_config)
        response = make_request(ANTHROPIC_URL, HTTP_POST, connection_config[:request_format], connection_config)
        success?(response) ? success_status : failure_status(nil)
      rescue StandardError => e
        handle_exception(e, { context: "ANTHROPIC:CHECK_CONNECTION:EXCEPTION", type: "error" })
        failure_status(e)
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, { context: "ANTHROPIC:DISCOVER:EXCEPTION", type: "error" })
      end

      def read(sync_config)
        # The server checks the ConnectorQueryType.
        # If it's "ai_ml," the server calculates the payload and passes it as a query in the sync config model protocol.
        # This query is then sent to the AI/ML model.
        connection_config = prepare_config(sync_config.source.connection_specification)
        stream = connection_config[:is_stream] ||= false
        payload = sync_config.model.query
        if stream
          run_model_stream(connection_config, payload) { |message| yield message if block_given? }
        else
          run_model(connection_config, payload)
        end
      rescue StandardError => e
        handle_exception(e, { context: "ANTHROPIC:READ:EXCEPTION", type: "error" })
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
        handle_exception(e, { context: "ANTHROPIC:PARSE_JSON:EXCEPTION", type: "error" })
        {}
      end

      def build_headers(connection_config, streaming: false)
        {
          "x-api-key" => connection_config[:api_key],
          "anthropic-version" => API_VERSION,
          "content-type" => "application/json"
        }.tap do |headers|
          headers["transfer-encoding"] = "chunked" if streaming
        end
      end

      def make_request(url, http_method, payload, connection_config)
        send_request(
          url: url,
          http_method: http_method,
          payload: JSON.parse(payload),
          headers: build_headers(connection_config, streaming: false),
          config: connection_config[:config]
        )
      end

      def run_model(connection_config, payload)
        response = make_request(ANTHROPIC_URL, HTTP_POST, payload, connection_config)
        process_response(response)
      rescue StandardError => e
        handle_exception(e, { context: "ANTHROPIC:RUN_MODEL:EXCEPTION", type: "error" })
      end

      def run_model_stream(connection_config, payload)
        send_streaming_request(
          url: ANTHROPIC_URL,
          http_method: HTTP_POST,
          payload: JSON.parse(payload),
          headers: build_headers(connection_config, streaming: true),
          config: connection_config[:config]
        ) do |chunk|
          process_streaming_response(chunk) { |message| yield message if block_given? }
        end
      rescue StandardError => e
        handle_exception(e, { context: "ANTHROPIC:RUN_STREAM_MODEL:EXCEPTION", type: "error" })
      end

      def process_response(response)
        if success?(response)
          data = JSON.parse(response.body)
          [RecordMessage.new(data: data, emitted_at: Time.now.to_i).to_multiwoven_message]
        else
          create_log_message("ANTHROPIC:RUN_MODEL", "error", "request failed: #{response.body}")
        end
      rescue StandardError => e
        handle_exception(e, { context: "ANTHROPIC:PROCESS_RESPONSE:EXCEPTION", type: "error" })
      end

      def check_chunk_error(chunk)
        return unless chunk.include?("{\"type\":\"error\"")

        data = JSON.parse(chunk)
        raise StandardError, "Error: #{data["error"]}" if data["error"] && data["error"]["message"]
      end

      def extract_content_event(chunk)
        events = chunk.split("\n\n")
        events.find { |e| e.include?("event: content_block_delta") }
      end

      def process_streaming_response(chunk)
        check_chunk_error(chunk)

        chunk.each_line do |event|
          next unless event.include?("\"type\":\"content_block_delta\"")

          json_string = event.split("\n").find { |line| line.start_with?("data: ") }&.sub(/^data: /, "")
          next unless json_string

          parsed_data = JSON.parse(json_string)
          yield [RecordMessage.new(data: parsed_data, emitted_at: Time.now.to_i).to_multiwoven_message] if block_given?
        end
      end
    end
  end
end
