# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module AwsBedrockModel
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        model = connection_config[:inference_profile] || connection_config[:model_id]
        payload = format_request(model, connection_config[:request_format])
        @client_runtime.invoke_model(
          model_id: model,
          content_type: "application/json",
          accept: "application/json",
          body: payload
        )
        success_status
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(_connection_config)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "AWS:BEDROCK MODEL:DISCOVER:EXCEPTION",
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
                           context: "AWS:BEDROCK MODEL:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def create_connection(connection_config)
        @client_runtime = Aws::BedrockRuntime::Client.new(
          region: connection_config[:region],
          access_key_id: connection_config[:access_key],
          secret_access_key: connection_config[:secret_access_key]
        )
      end

      def run_model(connection_config, payload)
        model = connection_config[:inference_profile] || connection_config[:model_id]
        payload = format_request(model, payload)
        response = @client_runtime.invoke_model(
          model_id: model,
          content_type: "application/json",
          accept: "application/json",
          body: payload
        )
        process_response(response)
      rescue StandardError => e
        handle_exception(e, context: "AWS:BEDROCK MODEL:RUN_MODEL:EXCEPTION", type: "error")
      end

      def process_response(response)
        data = JSON.parse(response.body.read)
        [RecordMessage.new(data: data, emitted_at: Time.now.to_i).to_multiwoven_message]
      end

      def format_request(model, payload)
        case model
        when *MISTRAL_AI_MODEL
          payload_request = JSON.parse(payload)
          prompt = payload_request["prompt"]
          payload_request["prompt"] = "<s>[INST] #{prompt} [/INST]" unless prompt.start_with?("<s>[INST]") && prompt.end_with?("[/INST]")
          payload_request.to_json
        else
          payload
        end
      end
    end
  end
end
