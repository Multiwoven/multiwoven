# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module Qdrant
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        api_url = connection_config[:api_url]
        api_key = connection_config[:api_key]

        response = Multiwoven::Integrations::Core::HttpClient.request(
          api_url,
          HTTP_GET,
          headers: auth_headers(api_key)
        )
        if success?(response)
          success_status
        else
          failure_status(nil)
        end
      rescue StandardError => e
        handle_exception(e, {
                           context: "QDRANT:CHECK_CONNECTION:EXCEPTION",
                           type: "error"
                         })
        failure_status(e)
      end

      def discover(connection_config = nil)
        connection_config = connection_config.with_indifferent_access
        @api_url = connection_config[:api_url]
        @api_key = connection_config[:api_key]

        response = Multiwoven::Integrations::Core::HttpClient.request(
          "#{@api_url}/collections",
          HTTP_GET,
          headers: auth_headers(@api_key)
        )

        data = JSON.parse(response.body)
        catalog = build_catalog(data)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "QDRANT:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def write(sync_config, records, _action = "upsert")
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        collection_name = sync_config.stream.name
        primary_key = sync_config.model.primary_key
        log_message_array = []

        api_url = connection_config[:api_url]
        api_key = connection_config[:api_key]

        write_success = 0
        write_failure = 0
        records.each do |record|
          points = []
          points.push({
                        id: record[primary_key],
                        vector: JSON.parse(record["vector"]),
                        payload: record["payload"]
                      })
          begin
            response = upsert_points(api_url, api_key, collection_name, { points: points })
            if success?(response)
              write_success += 1
              log_message_array << log_request_response("info", { points: points }, JSON.parse(response.body))
            else
              # write_failure could be duplicated if JSON.parse errors.
              write_failure += 1
              log_message_array << log_request_response("error", { points: points }, JSON.parse(response.body))
            end
          rescue StandardError => e
            handle_exception(e, {
                               context: "QDRANT:RECORD:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: sync_config.sync_id,
                               sync_run_id: sync_config.sync_run_id
                             })
            write_failure += 1
            log_message_array << log_request_response("error", { points: points }, e.message)
          end
        end
        tracking_message(write_success, write_failure, log_message_array)
      rescue StandardError => e
        handle_exception(e, {
                           context: "QDRANT:RECORD:WRITE:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def upsert_points(api_url, api_key, collection_name, payload)
        Multiwoven::Integrations::Core::HttpClient.request(
          api_url + "/collections/#{collection_name}/points",
          HTTP_PUT,
          payload: payload,
          headers: auth_headers(api_key)
        )
      end

      def build_catalog(data)
        streams = data["result"]["collections"].map { |collection| build_stream(collection) }
        Multiwoven::Integrations::Protocol::Catalog.new(
          streams: streams,
          request_rate_limit: 60,
          request_rate_limit_unit: "minute",
          request_rate_concurrency: 10
        )
      end

      def build_stream(collection)
        response = Multiwoven::Integrations::Core::HttpClient.request(
          "#{@api_url}/collections/#{collection["name"]}",
          HTTP_GET,
          headers: auth_headers(@api_key)
        )

        payload = { "type" => "object", "properties" => {} }
        if success?(response)
          data = JSON.parse(response.body)
          payload_schema = data["result"]["payload_schema"]
          payload_schema.each { |key, value| payload["properties"][key] = map_qdrant_types(value) } unless payload_schema.empty?
        end

        Multiwoven::Integrations::Protocol::Stream.new(
          name: collection["name"],
          action: "update",
          method: HTTP_PUT,
          supported_sync_modes: %w[incremental],
          json_schema: {
            "type" => "object",
            "required" => %w[id vector payload],
            "properties" => {
              "id" => {
                "type" => "string"
              },
              "payload" => payload,
              "vector" => {
                "type" => "vector"
              }
            }
          }
        )
      end

      def map_qdrant_types(value)
        case value["data_type"]
        when "integer"
          { "type" => "integer" }
        when "float"
          { "type" => "number" }
        when "bool"
          { "type" => "boolean" }
        when "geo"
          {
            "type" => "object",
            "required" => %w[lon lat],
            "properties" => {
              "lon" => {
                "type" => "number"
              },
              "lat" => {
                "type" => "number"
              }
            }
          }
        else
          # datetime, keyword, text, uuid
          { "type" => "string" }
        end
      end
    end
  end
end
