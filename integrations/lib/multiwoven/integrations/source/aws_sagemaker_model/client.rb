# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module AwsSagemakerModel
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        response = @client.describe_endpoint(endpoint_name: connection_config[:endpoint_name])
        if response.endpoint_status == "InService"
          success_status
        else
          failure_status
        end
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(_connection_config)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "AWS:SAGEMAKER MODEL:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification
        connection_config = connection_config.with_indifferent_access
        payload = sync_config.model.query
        create_connection(connection_config)
        run_model(connection_config, payload)
      rescue StandardError => e
        handle_exception(e, {
                           context: "AWS:SAGEMAKER MODEL:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def create_connection(connection_config)
        @client = Aws::SageMaker::Client.new(
          region: connection_config[:region],
          access_key_id: connection_config[:access_key],
          secret_access_key: connection_config[:secret_access_key]
        )

        @client_runtime = Aws::SageMakerRuntime::Client.new(
          region: connection_config[:region],
          access_key_id: connection_config[:access_key],
          secret_access_key: connection_config[:secret_access_key]
        )
      end

      def run_model(connection_config, payload)
        response = @client_runtime.invoke_endpoint(
          endpoint_name: connection_config[:endpoint_name],
          content_type: "application/json",
          body: payload
        )
        process_response(response)
      rescue StandardError => e
        handle_exception(e, context: "AWS:SAGEMAKER MODEL:RUN_MODEL:EXCEPTION", type: "error")
      end

      def process_response(response)
        data = JSON.parse(response.body.read)
        [RecordMessage.new(data: { response: data }, emitted_at: Time.now.to_i).to_multiwoven_message]
      end
    end
  end
end
