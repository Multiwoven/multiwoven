# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Aisquared
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      class AisquaredError < StandardError; end

      def check_connection(connection_config)
        response = make_request(lightning_embedding_url, HTTP_POST, connection_config[:request_format], connection_config)
        success?(response) ? success_status : failure_status(nil)
      rescue StandardError => e
        handle_exception(e, { context: "AISQUARED_LIGHTNING_ENDPOINT:CHECK_CONNECTION:EXCEPTION", type: "error" })
        failure_status(e)
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, { context: "AISQUARED_LIGHTNING_ENDPOINT:DISCOVER:EXCEPTION", type: "error" })
      end

      def read(sync_config)
        # The server checks the ConnectorQueryType.
        # If it's "ai_ml," the server calculates the payload and passes it as a query in the sync config model protocol.
        # This query is then sent to the AI/ML model.
        connection_config = sync_config.source.connection_specification
        payload = sync_config.model.query
        run_model(connection_config, payload)
      rescue StandardError => e
        handle_exception(e, { context: "AISQUARED_LIGHTNING_ENDPOINT:READ:EXCEPTION", type: "error" })
      end

      private

      def lightning_embedding_url
        host = AISQUARED_LIGHTNING_ENDPOINT_URL.to_s.strip
        raise AisquaredError, "AISQUARED_LIGHTNING_ENDPOINT_URL is not configured" if host.empty?

        "http://#{host.sub(%r{\Ahttps?://}, "")}/chat"
      end

      def parse_json(json_string)
        JSON.parse(json_string)
      rescue JSON::ParserError => e
        handle_exception(e, { context: "AISQUARED_LIGHTNING_ENDPOINT:PARSE_JSON:EXCEPTION", type: "error" })
        {}
      end

      # TODO: Re-add config for timeout when Lightning Endpoint supports it.
      def make_request(url, http_method, payload, _connection_config)
        send_request(
          url: url,
          http_method: http_method,
          payload: JSON.parse(payload),
          headers: { "Content-Type" => "application/json" }
        )
      end

      # TODO: Add support for streaming when Lightning Endpoint supports it.
      def run_model(connection_config, payload)
        response = make_request(lightning_embedding_url, HTTP_POST, payload, connection_config)
        process_response(response)
      rescue StandardError => e
        handle_exception(e, { context: "AISQUARED_LIGHTNING_ENDPOINT:RUN_MODEL:EXCEPTION", type: "error" })
      end

      def process_response(response)
        if success?(response)
          data = JSON.parse(response.body)
          [RecordMessage.new(data: data, emitted_at: Time.now.to_i).to_multiwoven_message]
        else
          create_log_message("AISQUARED_LIGHTNING_ENDPOINT:RUN_MODEL", "error", "request failed: #{response.body}")
        end
      rescue StandardError => e
        handle_exception(e, { context: "AISQUARED_LIGHTNING_ENDPOINT:PROCESS_RESPONSE:EXCEPTION", type: "error" })
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
