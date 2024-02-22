# frozen_string_literal: true

require "stringio"

module Multiwoven
  module Integrations
    module Destination
      module SalesforceCrm
        include Multiwoven::Integrations::Core

        API_VERSION = "59.0"

        class Client < DestinationConnector
          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            initialize_client(connection_config)
            authenticate_client
            success_status
          rescue StandardError => e
            failure_status(e)
          end

          def discover(_connection_config = nil)
            catalog = build_catalog(load_catalog_streams)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception("SALESFORCE:CRM:DISCOVER:EXCEPTION", "error", e)
          end

          def write(sync_config, records, action = "create")
            @action = sync_config.stream.action || action
            initialize_client(sync_config.destination.connection_specification)
            process_records(records, sync_config.stream)
          rescue StandardError => e
            handle_exception("SALESFORCE:CRM:WRITE:EXCEPTION", "error", e)
          end

          private

          def initialize_client(config)
            config = config.with_indifferent_access
            @client = Restforce.new(oauth_token: config[:access_token],
                                    refresh_token: config[:refresh_token],
                                    instance_url: config[:instance_url],
                                    client_id: config[:client_id],
                                    client_secret: config[:client_secret],
                                    authentication_callback: proc { |x| log_debug(x.to_s) },
                                    api_version: API_VERSION)
          end

          def process_records(records, stream)
            write_success = 0
            write_failure = 0
            properties = stream.json_schema[:properties]
            records.each do |record_object|
              record = extract_data(record_object, properties)
              process_record(stream, record)
              write_success += 1
            rescue StandardError => e
              handle_exception("SALESFORCE:CRM:WRITE:EXCEPTION", "error", e)
              write_failure += 1
            end
            tracking_message(write_success, write_failure)
          end

          def process_record(stream, record)
            send_data_to_salesforce(stream.name, record)
          end

          def send_data_to_salesforce(stream_name, record = {})
            method_name = "#{@action}!"
            args = build_args(@action, stream_name, record)
            @client.send(method_name, *args)
          end

          def build_args(action, stream_name, record)
            case action
            when :upsert
              [stream_name, record[:external_key], record]
            when :destroy
              [stream_name, record[:id]]
            else
              [stream_name, record]
            end
          end

          def authenticate_client
            @client.authenticate!
          end

          def success_status
            ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
          end

          def failure_status(error)
            ConnectionStatus.new(status: ConnectionStatusType["failed"], message: error.message).to_multiwoven_message
          end

          def load_catalog_streams
            catalog_json = read_json(CATALOG_SPEC_PATH)
            catalog_json["streams"].map { |stream| build_stream(stream) }
          end

          def build_stream(stream)
            Multiwoven::Integrations::Protocol::Stream.new(
              name: stream["name"], json_schema: stream["json_schema"],
              action: stream["action"]
            )
          end

          def build_catalog(streams)
            Multiwoven::Integrations::Protocol::Catalog.new(streams: streams)
          end

          def tracking_message(success, failure)
            Multiwoven::Integrations::Protocol::TrackingMessage.new(
              success: success, failed: failure
            ).to_multiwoven_message
          end

          def log_debug(message)
            Multiwoven::Integrations::Service.logger.debug(message)
          end
        end
      end
    end
  end
end
