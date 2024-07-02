# frozen_string_literal: true

require "stringio"
require_relative "schema_helper"

module Multiwoven
  module Integrations
    module Destination
      module SalesforceConsumerGoodsCloud
        include Multiwoven::Integrations::Core

        API_VERSION = "59.0"
        SALESFORCE_OBJECTS = %w[Account User Visit RetailStore RecordType].freeze

        class Client < DestinationConnector
          prepend Multiwoven::Integrations::Core::RateLimiter

          def initialize
            super
            @logger = Integrations::Service.logger
            Restforce.configure do |config|
              config.logger = @logger
            end
            Restforce.log = true
          end

          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            initialize_client(connection_config)
            authenticate_client
            success_status
          rescue StandardError => e
            failure_status(e)
          end

          def discover(connection_config)
            connection_config = connection_config.with_indifferent_access
            initialize_client(connection_config)
            catalog = build_catalog(load_catalog.with_indifferent_access)
            streams = catalog[:streams]
            SALESFORCE_OBJECTS.each do |object|
              object_description = @client.describe(object)
              streams << JSON.parse(SchemaHelper.create_json_schema_for_object(object_description).to_json)
            end
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception(e, {
                               context: "SALESFORCE:CONSUMER:GOODS:ClOUD:DISCOVER:EXCEPTION",
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
                               context: "SALESFORCE:CONSUMER:GOODS:ClOUD:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: @sync_config.sync_id,
                               sync_run_id: @sync_config.sync_run_id
                             })
          end

          private

          def initialize_client(config)
            config = config.with_indifferent_access
            @client = Restforce.new(username: config[:username],
                                    password: config[:password] + config[:security_token],
                                    host: config[:host],
                                    client_id: config[:client_id],
                                    client_secret: config[:client_secret],
                                    api_version: API_VERSION)
          end

          def process_records(records, stream)
            write_success = 0
            write_failure = 0
            properties = stream.json_schema[:properties]
            log_message_array = []

            records.each do |record_object|
              record = extract_data(record_object, properties)
              args = [stream.name, "Id", record]
              response = send_data_to_salesforce(args)
              write_success += 1
              log_message_array << log_request_response("info", args, response)
            rescue StandardError => e
              # TODO: add sync_id and sync run id to the logs
              handle_exception(e, {
                                 context: "SALESFORCE:CONSUMER:GOODS:ClOUD:WRITE:EXCEPTION",
                                 type: "error",
                                 sync_id: @sync_config.sync_id,
                                 sync_run_id: @sync_config.sync_run_id
                               })
              write_failure += 1
              log_message_array << log_request_response("error", args, e.message)
            end
            tracking_message(write_success, write_failure, log_message_array)
          end

          def send_data_to_salesforce(args)
            method_name = "upsert!"
            @logger.debug("sync_id: #{@sync_config.sync_id}, sync_run_id: #{@sync_config.sync_run_id}, args: #{args}")
            @client.send(method_name, *args)
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
