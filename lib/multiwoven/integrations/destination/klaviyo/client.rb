# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module Klaviyo
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      def check_connection(connection_config)
        api_key = connection_config[:private_api_key]

        response = Multiwoven::Integrations::Core::HttpClient.request(
          KLAVIYO_AUTH_ENDPOINT,
          HTTP_POST,
          payload: KLAVIYO_AUTH_PAYLOAD,
          headers: auth_headers(api_key)
        )
        parse_response(response)
      end

      def discover
        catalog = read_json(CATALOG_SPEC_PATH)

        catalog["streams"].map do |stream|
          Multiwoven::Integrations::Protocol::Stream.new(
            name: stream["name"],
            json_schema: stream["json_schema"],
            url: stream["url"],
            method: stream["method"],
            action: stream["action"]
          )
        end
      end

      def write(sync_config, records, _action = "insert")
        connection_config = sync_config.destination.connection_specification
        url = sync_config.stream.url
        request_method = sync_config.stream.request_method

        # TODO: Standerdise this across connectors
        tracker = {
          success: 0,
          failed: 0
        }

        records.each do |record|
          begin # rubocop:disable Style/RedundantBegin
            response = Multiwoven::Integrations::Core::HttpClient.request(
              url,
              request_method,
              payload: record,
              headers: auth_headers(connection_config["private_api_key"])
            )
            if success?(response)
              tracker[:success] += 1
            else
              tracker[:failed] += 1
            end
          rescue StandardError
            # TODO: Handle ratelimiting
            # TODO: Log error message
            tracker[:failed] += 1
          end
        end
        tracker
      end

      private

      def parse_response(response)
        if success?(response)
          ConnectionStatus.new(status: ConnectionStatusType["succeeded"])
        else
          message = extract_message(response)
          ConnectionStatus.new(status: ConnectionStatusType["failed"], message: message)
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
