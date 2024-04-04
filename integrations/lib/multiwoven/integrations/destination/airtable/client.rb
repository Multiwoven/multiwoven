# frozen_string_literal: true

require_relative "schema_helper"
module Multiwoven
  module Integrations
    module Destination
      module Airtable
        include Multiwoven::Integrations::Core
        class Client < DestinationConnector # rubocop:disable Metrics/ClassLength
          prepend Multiwoven::Integrations::Core::RateLimiter
          MAX_CHUNK_SIZE = 10
          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            bases = Multiwoven::Integrations::Core::HttpClient.request(
              AIRTABLE_BASES_ENDPOINT,
              HTTP_GET,
              headers: auth_headers(connection_config[:api_key])
            )
            if success?(bases)
              base_id_exists?(bases, connection_config[:base_id])
              success_status
            else
              failure_status(nil)
            end
          rescue StandardError => e
            failure_status(e)
          end

          def discover(connection_config)
            connection_config = connection_config.with_indifferent_access
            base_id = connection_config[:base_id]
            api_key = connection_config[:api_key]

            bases = Multiwoven::Integrations::Core::HttpClient.request(
              AIRTABLE_BASES_ENDPOINT,
              HTTP_GET,
              headers: auth_headers(api_key)
            )

            base = extract_bases(bases).find { |b| b["id"] == base_id }
            base_name = base["name"]

            schema = Multiwoven::Integrations::Core::HttpClient.request(
              AIRTABLE_GET_BASE_SCHEMA_ENDPOINT.gsub("{baseId}", base_id),
              HTTP_GET,
              headers: auth_headers(api_key)
            )

            catalog = build_catalog_from_schema(extract_body(schema), base_id, base_name)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception("AIRTABLE:DISCOVER:EXCEPTION", "error", e)
          end

          def write(sync_config, records, _action = "create")
            connection_config = sync_config.destination.connection_specification.with_indifferent_access
            api_key = connection_config[:api_key]
            url = sync_config.stream.url
            write_success = 0
            write_failure = 0
            records.each_slice(MAX_CHUNK_SIZE) do |chunk|
              payload = create_payload(chunk)
              response = Multiwoven::Integrations::Core::HttpClient.request(
                url,
                sync_config.stream.request_method,
                payload: payload,
                headers: auth_headers(api_key)
              )
              if success?(response)
                write_success += chunk.size
              else
                write_failure += chunk.size
              end
            rescue StandardError => e
              handle_exception("AIRTABLE:RECORD:WRITE:EXCEPTION", "error", e)
              write_failure += chunk.size
            end

            tracker = Multiwoven::Integrations::Protocol::TrackingMessage.new(
              success: write_success,
              failed: write_failure
            )
            tracker.to_multiwoven_message
          rescue StandardError => e
            handle_exception("AIRTABLE:WRITE:EXCEPTION", "error", e)
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

          def auth_headers(access_token)
            {
              "Accept" => "application/json",
              "Authorization" => "Bearer #{access_token}",
              "Content-Type" => "application/json"
            }
          end

          def base_id_exists?(bases, base_id)
            return if extract_data(bases).any? { |base| base["id"] == base_id }

            raise ArgumentError, "base_id not found"
          end

          def extract_bases(response)
            response_body = extract_body(response)
            response_body["bases"] if response_body
          end

          def extract_body(response)
            response_body = response.body
            JSON.parse(response_body) if response_body
          end

          def load_catalog
            read_json(CATALOG_SPEC_PATH)
          end

          def create_stream(table, base_id, base_name)
            {
              name: "#{base_name}/#{SchemaHelper.clean_name(table["name"])}",
              action: "create",
              method: HTTP_POST,
              url: "#{AIRTABLE_URL_BASE}#{base_id}/#{table["id"]}",
              json_schema: SchemaHelper.get_json_schema(table),
              supported_sync_modes: %w[incremental],
              batch_support: true,
              batch_size: 10

            }.with_indifferent_access
          end

          def build_catalog_from_schema(schema, base_id, base_name)
            catalog = build_catalog(load_catalog)
            schema["tables"].each do |table|
              catalog.streams << build_stream(create_stream(table, base_id, base_name))
            end
            catalog
          end
        end
      end
    end
  end
end
