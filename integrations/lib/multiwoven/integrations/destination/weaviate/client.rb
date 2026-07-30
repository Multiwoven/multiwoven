# frozen_string_literal: true

require "weaviate"
require "digest"
module Multiwoven::Integrations::Destination
  module Weaviate
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      WEAVIATE_TYPE_MAP = {
        "text" => "string",
        "int" => "integer",
        "number" => "number",
        "boolean" => "boolean",
        "date" => "string"
      }.freeze
      def check_connection(connection_config)
        client = build_client(connection_config)
        client.schema.list
        success_status
      rescue StandardError => e
        handle_exception(e, {
                           context: "WEAVIATE:CHECK_CONNECTION:EXCEPTION",
                           type: "error"
                         })
        failure_status(e)
      end

      def discover(connection_config)
        client = build_client(connection_config)
        schema = client.schema.list
        classes = schema["classes"] || []
        streams = classes.map { |class_data| build_stream(class_data) }
        catalog = build_catalog(streams)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "WEAVIATE:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def write(sync_config, records, _action = "destination_insert")
        write_success = 0
        write_failure = 0
        log_message_array = []
        # Passing in the id handles upsert
        objects = records.map do |record|
          {
            class: sync_config.stream.name,
            vector: record["vector"],
            id: record["id"].present? ? generate_uuid(record["id"]) : SecureRandom.uuid,
            properties: coerce_properties(record["properties"], sync_config.stream)
          }
        end

        client = build_client(sync_config.destination.connection_specification)
        responses = client.objects.batch_create(objects: objects)
        responses.each do |response|
          if response["result"]["status"] == "SUCCESS"
            write_success += 1
            log_message_array << log_request_response("info", { object: response }, response)
          else
            write_failure += 1
            log_message_array << log_request_response("error", { object: response }, response)
          end
        end
        tracking_message(write_success, write_failure, log_message_array)
      rescue StandardError => e
        handle_exception(e, {
                           context: "WEAVIATE:RECORD:WRITE:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def normalize_url(url)
        url = url.to_s.strip.downcase
        url = url.delete_prefix("www.")
        url = "https://#{url}" unless url.start_with?("http://", "https://")
        url.chomp("/")
      end

      def build_client(connection_config)
        connection_config = connection_config.with_indifferent_access
        ::Weaviate::Client.new(
          url: normalize_url(connection_config[:api_url]),
          api_key: connection_config[:api_key],
          logger: Logger.new($stdout, level: Logger::ERROR)
        )
      end

      def build_stream(class_data)
        properties = {}
        class_data["properties"].each do |property|
          properties[property["name"]] = { "type" => WEAVIATE_TYPE_MAP[property["dataType"][0]] } unless property["name"] == "vector"
        end

        Multiwoven::Integrations::Protocol::Stream.new(
          name: class_data["class"], # Weaviate class name
          action: "update", # or "update"
          supported_sync_modes: %w[incremental],
          json_schema: {
            "type" => "object",
            "required" => %w[id vector properties],
            "properties" => {
              "id" => { "type" => "string", "required" => true },
              "vector" => { "type" => "vector", "required" => true },
              "properties" => {
                "type" => "object",
                "required" => %w[properties],
                "properties" => properties

              }
            }
          }
        )
      end

      def build_catalog(streams)
        Multiwoven::Integrations::Protocol::Catalog.new(
          streams: streams,
          request_rate_limit: 60,
          request_rate_limit_unit: "minute",
          request_rate_concurrency: 10
        )
      end

      def generate_uuid(str)
        hash = Digest::SHA1.hexdigest(str)
        "#{hash[0, 8]}-#{hash[8, 4]}-#{hash[12, 4]}-#{hash[16, 4]}-#{hash[20, 12]}"
      end

      def coerce_properties(properties, stream)
        schema_props = stream.json_schema.with_indifferent_access.dig("properties", "properties", "properties") || {}
        properties.each_with_object({}) do |(key, value), result|
          result[key] = case schema_props.dig(key, "type")
                        when "integer" then value.to_i
                        when "number"  then value.to_f
                        when "boolean" then value.to_s.downcase == "true"
                        else value
                        end
        end
      end
    end
  end
end
