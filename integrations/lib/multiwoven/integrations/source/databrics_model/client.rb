# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module DatabricksModel
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        url = build_url(DATABRICKS_HEALTH_URL, connection_config)
        response = Multiwoven::Integrations::Core::HttpClient.request(
          url,
          HTTP_GET,
          headers: auth_headers(connection_config[:token])
        )
        if success?(response)
          success_status
        else
          failure_status(nil)
        end
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "DATABRICKS MODEL:DISCOVER:EXCEPTION",
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
                           context: "DATABRICKS MODEL:READ:EXCEPTION",
                           type: "error"
                         })
      end

      private

      def run_model(connection_config, payload)
        connection_config = connection_config.with_indifferent_access

        url = build_url(DATABRICKS_SERVING_URL, connection_config)
        token = connection_config[:token]
        response = send_request(url, token, payload)
        process_response(response)
      rescue StandardError => e
        handle_exception(e, context: "DATABRICKS MODEL:RUN_MODEL:EXCEPTION", type: "error")
      end

      def process_response(response)
        if success?(response)
          begin
            data = JSON.parse(response.body)
            [RecordMessage.new(data: data, emitted_at: Time.now.to_i).to_multiwoven_message]
          rescue JSON::ParserError
            create_log_message("DATABRICKS MODEL:RUN_MODEL", "error", "parsing failed: please send a valid payload")
          end
        else
          create_log_message("DATABRICKS MODEL:RUN_MODEL", "error", "request failed: #{response.body}")
        end
      end

      def build_url(url, connection_config)
        format(url, databricks_host: connection_config[:databricks_host],
                    endpoint_name: connection_config[:endpoint])
      end

      def send_request(url, token, payload)
        Multiwoven::Integrations::Core::HttpClient.request(
          url,
          HTTP_POST,
          payload: payload,
          headers: auth_headers(token)
        )
      end
    end
  end
end
