# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Destination
      module Stripe
        include Multiwoven::Integrations::Core

        API_VERSION = "59.0"

        class Client < DestinationConnector
          prepend Multiwoven::Integrations::Core::RateLimiter
          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            initialize_client(connection_config)
            authenticate_client
            success_status
          rescue StandardError => e
            failure_status(e)
          end

          def discover(_connection_config = nil)
            catalog = build_catalog(load_catalog)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception(e, {
                               context: "STRIPE:CRM:DISCOVER:EXCEPTION",
                               type: "error"
                             })
          end

          def write(sync_config, records, action = "create")
            @sync_config = sync_config
            @action = sync_config.stream.action || action
            initialize_client(sync_config.destination.connection_specification)
            process_records(records, sync_config.stream)
          rescue StandardError => e
            handle_exception(e, {
                               context: "STRIPE:CRM:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: @sync_config.sync_id,
                               sync_run_id: @sync_config.sync_run_id
                             })
          end

          private

          def initialize_client(config)
            config = config.with_indifferent_access
            ::Stripe.api_key = config[:api_key]
            @client = ::Stripe
          end

          def process_records(records, stream)
            log_message_array = []
            write_success = 0
            write_failure = 0
            properties = stream.json_schema[:properties]
            records.each do |record_object|
              record = extract_data(record_object, properties)
              args = [stream.name, "Id", record]
              klass = @client.const_get(stream.name)
              response = klass.send(@action, record)
              write_success += 1
              log_message_array << log_request_response("info", args, response)
            rescue StandardError => e
              handle_exception(e, {
                                 context: "STRIPE:CRM:WRITE:EXCEPTION",
                                 type: "error",
                                 sync_id: @sync_config.sync_id,
                                 sync_run_id: @sync_config.sync_run_id
                               })
              write_failure += 1
              log_message_array << log_request_response("error", args, e.message)
            end
            tracking_message(write_success, write_failure, log_message_array)
          end

          def authenticate_client
            @client::Customer.list
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
