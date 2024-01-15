# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module Klaviyo
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        api_key = connection_config[:private_api_key]

        response = Multiwoven::Integrations::Core::HttpClient.request(
          KLAVIYO_AUTH_ENDPOINT,
          HTTP_POST,
          payload: KLAVIYO_AUTH_PAYLOAD,
          headers: auth_headers(api_key)
        )
        parse_response(response)
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)

        streams = catalog_json["streams"].map do |stream|
          Multiwoven::Integrations::Protocol::Stream.new(
            name: stream["name"],
            json_schema: stream["json_schema"],
            url: stream["url"],
            request_method: stream["method"],
            action: stream["action"]
          )
        end

        catalog = Multiwoven::Integrations::Protocol::Catalog.new(
          streams: streams
        )

        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(
          "KLAVIYO:DISCOVER:EXCEPTION",
          "error",
          e
        )
      end

      def write(sync_config, records, _action = "insert")
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        connection_config = connection_config.with_indifferent_access
        url = sync_config.stream.url
        request_method = sync_config.stream.request_method

        write_success = 0
        write_failure = 0
        records.each do |record|
          response = Multiwoven::Integrations::Core::HttpClient.request(
            url,
            request_method,
            payload: record,
            headers: auth_headers(connection_config["private_api_key"])
          )
          if success?(response)
            write_success += 1
          else
            write_failure += 1
          end
        rescue StandardError => e
          logger.error(
            "KLAVIYO:RECORD:WRITE:FAILURE: #{e.message}"
          )
          write_failure += 1
        end
        tracker = Multiwoven::Integrations::Protocol::TrackingMessage.new(
          success: write_success,
          failed: write_failure
        )
        tracker.to_multiwoven_message
      rescue StandardError => e
        # TODO: Handle rate limiting seperately
        handle_exception(
          "KLAVIYO:WRITE:EXCEPTION",
          "error",
          e
        )
      end

      private

      def parse_response(response)
        if success?(response)
          ConnectionStatus.new(
            status: ConnectionStatusType["succeeded"]
          ).to_multiwoven_message
        else
          message = extract_message(response)
          ConnectionStatus.new(
            status: ConnectionStatusType["failed"], message: message
          ).to_multiwoven_message
        end
      end

      def success?(response)
        response && %w[200 201].include?(response.code)
      end

      def extract_message(response)
        JSON.parse(response.body)["message"]
      rescue StandardError => e
        "Klaviyo auth failed: #{e.message}"
      end

      def auth_headers(api_key)
        {
          "Accept" => "application/json",
          "Authorization" => "Klaviyo-API-Key #{api_key}",
          "Revision" => "2023-02-22",
          "Content-Type" => "application/json"
        }
      end
    end
  end
end
