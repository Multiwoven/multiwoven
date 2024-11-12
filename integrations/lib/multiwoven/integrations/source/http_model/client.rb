# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module HttpModel
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        url_host = connection_config[:url_host]
        headers = connection_config[:headers]
        response = Multiwoven::Integrations::Core::HttpClient.request(
          url_host,
          HTTP_GET,
          headers: headers
        )
        if success?(response)
          success_status
        else
          failure_status(nil)
        end
      rescue StandardError => e
        handle_exception(e, {
                           context: "HTTP MODEL:CHECK_CONNECTION:EXCEPTION",
                           type: "error"
                         })
        failure_status(e)
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "HTTP MODEL:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification
        connection_config = connection_config.with_indifferent_access
        # The server checks the ConnectorQueryType.
        # If it's "ai_ml," the server calculates the payload and passes it as a query in the sync config model protocol.
        # This query is then sent to the AI/ML model.
        payload = JSON.parse(sync_config.model.query)
        run_model(connection_config, payload)
      rescue StandardError => e
        handle_exception(e, {
                           context: "HTTP MODEL:READ:EXCEPTION",
                           type: "error"
                         })
      end

      private

      def run_model(connection_config, payload)
        connection_config = connection_config.with_indifferent_access
        url_host = connection_config[:url_host]
        headers = connection_config[:headers]
        config = connection_config[:config]
        config[:timeout] ||= 30
        response = send_request(url_host, payload, headers, config)
        process_response(response)
      rescue StandardError => e
        handle_exception(e, context: "HTTP MODEL:RUN_MODEL:EXCEPTION", type: "error")
      end

      def process_response(response)
        if success?(response)
          data = JSON.parse(response.body)
          [RecordMessage.new(data: data, emitted_at: Time.now.to_i).to_multiwoven_message]
        else
          create_log_message("HTTP MODEL:RUN_MODEL", "error", "request failed")
        end
      end

      def send_request(url, payload, headers, config)
        Multiwoven::Integrations::Core::HttpClient.request(
          url,
          HTTP_POST,
          payload: payload,
          headers: headers,
          config: config
        )
      end
    end
  end
end
