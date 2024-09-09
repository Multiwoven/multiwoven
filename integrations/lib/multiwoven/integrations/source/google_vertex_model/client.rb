# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module VertexModel
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        @client.get_endpoint(name: build_url(GOOGLE_VERTEX_MODEL_NAME, connection_config))
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "GOOGLE:VERTEX MODEL:DISCOVER:EXCEPTION",
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
                           context: "GOOGLE:VERTEX MODEL:READ:EXCEPTION",
                           type: "error"
                         })
      end

      private

      def create_connection(connection_config)
        Google::Cloud::AIPlatform::V1::EndpointService::Client.configure do |config|
          config.endpoint = build_url(GOOGLE_VERTEX_ENDPOINT_SERVICE_URL, connection_config)
          config.credentials = connection_config["credentials_json"]
        end
        Google::Cloud::AIPlatform::V1::PredictionService::Client.configure do |config|
          config.endpoint = build_url(GOOGLE_VERTEX_ENDPOINT_SERVICE_URL, connection_config)
          config.credentials = connection_config["credentials_json"]
        end
        @client = Google::Cloud::AIPlatform::V1::EndpointService::Client.new
        @endpoint = Google::Cloud::AIPlatform::V1::PredictionService::Client.new
      end

      def run_model(connection_config, payload)
        create_connection(connection_config)
        http_body = Google::Api::HttpBody.new(data: JSON.generate(payload))
        response = @endpoint.raw_predict(endpoint: build_url(GOOGLE_VERTEX_MODEL_NAME, connection_config), http_body: http_body)
        process_response(response)
      rescue StandardError => e
        handle_exception(e, context: "GOOGLE:VERTEX MODEL:RUN_MODEL:EXCEPTION", type: "error")
      end

      def process_response(response)
        data = JSON.parse(response.data)
        [RecordMessage.new(data: data, emitted_at: Time.now.to_i).to_multiwoven_message]
      end

      def build_url(url, connection_config)
        case url
        when GOOGLE_VERTEX_MODEL_NAME
          format(url, project_id: connection_config[:project_id],
                      region: connection_config[:region],
                      endpoint_id: connection_config[:endpoint_id])
        when GOOGLE_VERTEX_ENDPOINT_SERVICE_URL
          format(url, region: connection_config[:region])
        end
      end
    end
  end
end
