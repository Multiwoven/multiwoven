# frozen_string_literal: true

require "uri"
require "net/http"
require "json"

module Multiwoven
  module Integrations
    module Destination
      module Mixpanel
        include Multiwoven::Integrations::Core

        class Client < DestinationConnector
          prepend Multiwoven::Integrations::Core::RateLimiter

          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            initialize_client(connection_config)
            validate_connection
            success_status
          rescue StandardError => e
            failure_status(e)
          end

          def discover(_connection_config = nil)
            catalog = build_catalog(load_catalog)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception(e, {
                               context: "MIXPANEL:DISCOVER:EXCEPTION",
                               type: "error"
                             })
          end

          def write(sync_config, records, _action = "create")
            @sync_config = sync_config
            initialize_client(sync_config.destination.connection_specification)
            process_records(records, sync_config.stream)
          rescue StandardError => e
            handle_exception(e, {
                               context: "MIXPANEL:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: @sync_config.sync_id,
                               sync_run_id: @sync_config.sync_run_id
                             })
          end

          private

          def initialize_client(config)
            config = config.with_indifferent_access
            @api_token = config[:api_token]
            raise "API token is required for Mixpanel" unless @api_token
          end

          def process_records(records, stream)
            log_message_array = []
            write_success = 0
            write_failure = 0
            properties = stream.json_schema[:properties]

            records.each do |record_object|
              record = extract_data(record_object, properties)
              begin
                response = send_to_mixpanel(record, stream.name)
                write_success += 1
                log_message_array << log_request_response("info", [stream.name, record], response)
              rescue StandardError => e
                handle_exception(e, {
                                   context: "MIXPANEL:WRITE:EXCEPTION",
                                   type: "error",
                                   sync_id: @sync_config.sync_id,
                                   sync_run_id: @sync_config.sync_run_id
                                 })
                write_failure += 1
                log_message_array << log_request_response("error", [stream.name, record], e.message)
              end
            end
            tracking_message(write_success, write_failure, log_message_array)
          end

          def send_to_mixpanel(record, stream_name)
            stream_config = {
              "UserProfiles" => {
                endpoint: "#{MIXPANEL_BASE_URL}/engage#profile-set",
                payload: lambda { |record|
                  [{
                    "$token" => @api_token,
                    "$distinct_id" => record[:id],
                    "$set" => record[:properties]
                  }]
                }
              },
              "Events" => {
                endpoint: "#{MIXPANEL_BASE_URL}/track",
                payload: lambda { |record|
                  [{
                    "event" => record[:name],
                    "properties" => record[:properties].merge("token" => @api_token)
                  }]
                }
              }
            }

            config = stream_config[stream_name]
            raise "Unsupported stream: #{stream_name}" unless config

            endpoint = config[:endpoint]
            payload = config[:payload].call(record)

            send_request(endpoint, payload)
          end

          def send_request(endpoint, payload)
            url = URI(endpoint)

            http = Net::HTTP.new(url.host, url.port)
            http.use_ssl = true

            request = Net::HTTP::Post.new(url)
            request["accept"] = "text/plain"
            request["content-type"] = "application/json"

            formatted_payload = payload.is_a?(Array) ? payload.map { |item| item.transform_keys(&:to_s) } : payload.transform_keys(&:to_s)
            request.body = formatted_payload.to_json

            response = http.request(request)
            handle_response(response)
          end

          def handle_response(response)
            case response.code.to_i
            when 200
              JSON.parse(response.body)
            when 401
              raise "Authentication Error: Invalid API token."
            when 403
              raise "Forbidden Error: API request refused."
            when 429
              raise "Rate Limit Error: Too many requests."
            else
              raise "Error: #{response.code} - #{response.body}"
            end
          end

          def validate_connection
            test_payload = {
              "event" => "Test Event",
              "properties" => { "$token" => @api_token }
            }
            response = send_request("#{MIXPANEL_BASE_URL}/track", test_payload)
            raise "Connection failed" unless response["status"] == 1
          end

          def load_catalog
            read_json(CATALOG_SPEC_PATH)
          end

          def log_debug(message)
            Multiwoven::Integrations::Service.logger.debug(message)
          end
        end
      end
    end
  end
end
