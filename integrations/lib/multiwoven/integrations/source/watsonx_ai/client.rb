# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module WatsonxAi
    include Multiwoven::Integrations::Core
    API_VERSION = "2021-05-01"
    class Client < SourceConnector
      def check_connection(connection_config)
        get_access_token(connection_config[:api_key])
        url = format(
          WATSONX_HEALTH_DEPLOYMENT_URL,
          region: connection_config[:region],
          version: API_VERSION
        )
        response = send_request(
          url: url,
          http_method: HTTP_GET,
          payload: {},
          headers: auth_headers(@access_token),
          config: connection_config[:config]
        )
        evaluate_deployment_status(response, connection_config[:deployment_id])
      rescue StandardError => e
        handle_exception(e, { context: "WATSONX AI:CHECK_CONNECTION:EXCEPTION", type: "error" })
        failure_status(e)
      end

      def discover(_connection_config)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, { context: "WATSONX AI:DISCOVER:EXCEPTION", type: "error" })
      end

      def read(sync_config)
        connection_config, payload = prepare_config_and_payload(sync_config)
        process_model_request(connection_config, payload) { |message| yield message if block_given? }
      rescue StandardError => e
        handle_exception(e, { context: "WATSONX AI:READ:EXCEPTION", type: "error" })
      end

      private

      def process_model_request(connection_config, payload)
        if connection_config[:is_stream] && connection_config[:model_type] == "Prompt template"
          run_model_stream(connection_config, payload) { |message| yield message if block_given? }
        else
          run_model(connection_config, payload)
        end
      end

      def evaluate_deployment_status(response, deployment_id)
        response_body = JSON.parse(response.body)
        deployment_status = response_body["resources"]&.find { |res| res.dig("metadata", "id") == deployment_id }

        return failure_status unless deployment_status

        deployment_status.dig("entity", "status", "state") == "ready" ? success_status : failure_status
      end

      def prepare_config_and_payload(sync_config)
        config = sync_config.source.connection_specification
        connection_config = config.with_indifferent_access.tap do |conf|
          conf[:config][:timeout] ||= 30
          conf[:is_stream] ||= false
        end
        payload = sync_config.model.query
        [connection_config, payload]
      end

      def get_access_token(api_key)
        cache = defined?(Rails) && Rails.respond_to?(:cache) ? Rails.cache : ActiveSupport::Cache::MemoryStore.new
        cache_key = "watsonx_ai_#{api_key}"
        cached_token = cache.read(cache_key)
        if cached_token
          @access_token = cached_token
        else
          new_token = get_iam_token(api_key)
          # max expiration is 3 minutes. No way to make it higher
          cache.write(cache_key, new_token, expires_in: 180)
          @access_token = new_token
        end
      end

      def get_iam_token(api_key)
        uri = URI("https://iam.cloud.ibm.com/identity/token")
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/x-www-form-urlencoded"
        request.body = "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=#{api_key}"
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        raise "Failed to get IAM token: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)["access_token"]
      end

      def parse_json(json_string)
        JSON.parse(json_string)
      rescue JSON::ParserError => e
        handle_exception(e, { context: "OPEN AI:PARSE_JSON:EXCEPTION", type: "error" })
        {}
      end

      def run_model(connection_config, payload)
        get_access_token(connection_config[:api_key])
        url = format(
          connection_config[:model_type] == "Machine learning model" ? WATSONX_PREDICTION_DEPLOYMENT_URL : WATSONX_GENERATION_DEPLOYMENT_URL,
          region: connection_config[:region],
          deployment_id: connection_config[:deployment_id],
          version: API_VERSION
        )
        response = send_request(
          url: url,
          http_method: HTTP_POST,
          payload: JSON.parse(payload),
          headers: auth_headers(@access_token),
          config: connection_config[:config]
        )
        process_response(response)
      rescue StandardError => e
        handle_exception(e, { context: "WATSONX AI:RUN_MODEL:EXCEPTION", type: "error" })
      end

      def process_response(response)
        if success?(response)
          if response.body.start_with?("{") || response.body.start_with?("[")
            data = JSON.parse(response.body)
            [RecordMessage.new(data: data, emitted_at: Time.now.to_i).to_multiwoven_message]
          else
            data = format_data(response.body)
            RecordMessage.new(data: { responses: data }, emitted_at: Time.now.to_i).to_multiwoven_message
          end
        else
          create_log_message("WATSONX AI:RUN_MODEL", "error", "request failed: #{response.body}")
        end
      rescue StandardError => e
        handle_exception(e, { context: "WATSONX AI:PROCESS_RESPONSE:EXCEPTION", type: "error" })
      end

      def run_model_stream(connection_config, payload)
        get_access_token(connection_config[:api_key])
        url = format(
          WATSONX_STREAM_DEPLOYMENT_URL,
          region: connection_config[:region],
          deployment_id: connection_config[:deployment_id],
          version: API_VERSION
        )
        send_streaming_request(
          url: url,
          http_method: HTTP_POST,
          payload: JSON.parse(payload),
          headers: auth_headers(@access_token),
          config: connection_config[:config]
        ) do |chunk|
          process_streaming_response(chunk) { |message| yield message if block_given? }
        end
      rescue StandardError => e
        handle_exception(e, { context: "WATSONX AI:RUN_STREAM_MODEL:EXCEPTION", type: "error" })
      end

      def format_data(response_body)
        messages = response_body.split("\n\n")
        messages.map do |message|
          match = message.match(/data:\s*(\{.*\})/)
          match ? JSON.parse(match[1]) : nil
        end.compact
      end

      def extract_data_entries(chunk)
        chunk.split(/^data: /).map(&:strip).reject(&:empty?)
      end

      def process_streaming_response(chunk)
        data_entries = extract_data_entries(chunk)
        data_entries.each do |entry|
          data, = entry.split("\n", 2)

          next if data == "id: 1"

          data = parse_json(data)

          raise StandardError, "Error: #{data["errors"][0]["message"]}" if data["errors"] && data["errors"][0]["message"]

          next if data["results"][0]["stop_reason"] != "not_finished"

          yield [RecordMessage.new(data: data, emitted_at: Time.now.to_i).to_multiwoven_message] if block_given?
        end
      end
    end
  end
end
