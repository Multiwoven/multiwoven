# frozen_string_literal: true

require "base64"
module Multiwoven
  module Integrations
    module Destination
      module Http
        include Multiwoven::Integrations::Core
        class Client < DestinationConnector
          MAX_CHUNK_SIZE = 10
          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            destination_url = connection_config[:destination_url]
            request = Multiwoven::Integrations::Core::HttpClient.request(
              destination_url,
              HTTP_OPTIONS
            )
            if success?(request)
              success_status
            else
              failure_status(nil)
            end
          rescue StandardError => e
            handle_exception("HTTP:CHECK_CONNECTION:EXCEPTION", "error", e)
            failure_status(e)
          end

          def discover(_connection_config = nil)
            catalog_json = read_json(CATALOG_SPEC_PATH)
            catalog = build_catalog(catalog_json)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception(
              "HTTP:DISCOVER:EXCEPTION",
              "error",
              e
            )
          end

          def write(sync_config, records, _action = "create")
            connection_config = sync_config.destination.connection_specification.with_indifferent_access

            url = connection_config[:destination_url]
            headers = connection_config[:headers]
            write_success = 0
            write_failure = 0
            records.each_slice(MAX_CHUNK_SIZE) do |chunk|
              payload = create_payload(chunk)
              response = Multiwoven::Integrations::Core::HttpClient.request(
                url,
                sync_config.stream.request_method,
                payload: payload,
                headers: headers
              )
              if success?(response)
                write_success += chunk.size
              else
                write_failure += chunk.size
              end
            rescue StandardError => e
              handle_exception("HTTP:RECORD:WRITE:EXCEPTION", "error", e)
              write_failure += chunk.size
            end

            tracker = Multiwoven::Integrations::Protocol::TrackingMessage.new(
              success: write_success,
              failed: write_failure
            )
            tracker.to_multiwoven_message
          rescue StandardError => e
            handle_exception("HTTP:WRITE:EXCEPTION", "error", e)
          end

          private

          def create_payload(records)
            {
              "records" => records.map do |record|
                {
                  "fields" => record
                }
              end
            }
          end

          def convert_to_auth_key(username, password)
            full_string = "#{username}:#{password}"
            # need to remove line break after encoding or else request fails
            Base64.encode64(full_string).gsub(/\n/, "")
          end

          def extract_body(response)
            response_body = response.body
            JSON.parse(response_body) if response_body
          end
        end
      end
    end
  end
end
