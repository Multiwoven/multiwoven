# frozen_string_literal: true

require "stringio"

module Multiwoven
  module Integrations
    module Destination
      module Hubspot
        include Multiwoven::Integrations::Core

        class Client < DestinationConnector
          prepend Multiwoven::Integrations::Core::RateLimiter
          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            initialize_client(connection_config)
            authenticate_client
            success_status
          rescue StandardError => e
            handle_exception(e, {
                               context: "HUBSPOT:CRM:CHECK_CONNECTION:EXCEPTION",
                               type: "error"
                             })
            failure_status(e)
          end

          def discover(_connection_config = nil)
            catalog = build_catalog(load_catalog)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception(e, {
                               context: "HUBSPOT:CRM:DISCOVER:EXCEPTION",
                               type: "error"
                             })
          end

          def write(sync_config, records, action = "create")
            @action = sync_config.stream.action || action
            @sync_config = sync_config
            initialize_client(sync_config.destination.connection_specification)
            process_records(records, sync_config.stream)
          rescue StandardError => e
            handle_exception(e, {
                               context: "HUBSPOT:CRM:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: @sync_config.sync_id,
                               sync_run_id: @sync_config.sync_run_id
                             })
          end

          private

          def initialize_client(config)
            config = config.with_indifferent_access
            @client = ::Hubspot::Client.new(access_token: config[:access_token])
          end

          def process_records(records, stream)
            log_message_array = []
            write_success = 0
            write_failure = 0
            properties = stream.json_schema.with_indifferent_access[:properties]
            records.each do |record_object|
              record = extract_data(record_object, properties)
              request, response = *send_data_to_hubspot(stream.name, record)
              write_success += 1
              log_message_array << log_request_response("info", request, response)
            rescue StandardError => e
              handle_exception(e, {
                                 context: "HUBSPOT:CRM:WRITE:EXCEPTION",
                                 type: "error",
                                 sync_id: @sync_config.sync_id,
                                 sync_run_id: @sync_config.sync_run_id
                               })
              write_failure += 1
              log_message_array << log_request_response("error", request, e.message)
            end
            tracking_message(write_success, write_failure, log_message_array)
          end

          def send_data_to_hubspot(stream_name, record = {})
            args = build_args(@action, stream_name, record)
            hubspot_stream = @client.crm.send(stream_name)
            hubspot_data = { simple_public_object_input_for_create: args }
            response = hubspot_stream.basic_api.send(@action, hubspot_data)
            [args, response]
          end

          def build_args(action, stream_name, record)
            case action
            when :upsert
              [stream_name, record[:external_key], record]
            when :destroy
              [stream_name, record[:id]]
            else
              record
            end
          end

          def authenticate_client
            @client.crm.contacts.basic_api.get_page
          end

          def success_status
            ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
          end

          def failure_status(error)
            ConnectionStatus.new(status: ConnectionStatusType["failed"], message: error.message).to_multiwoven_message
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
