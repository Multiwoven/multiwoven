# frozen_string_literal: true

require "stringio"
require_relative "schema_helper"

module Multiwoven
  module Integrations
    module Source
      module SalesforceConsumerGoodsCloud
        include Multiwoven::Integrations::Core

        API_VERSION = "59.0"
        SALESFORCE_OBJECTS = %w[Account User Visit RetailStore RecordType].freeze

        class Client < SourceConnector
          prepend Multiwoven::Integrations::Core::RateLimiter
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

          def read(sync_config)
            connection_config = sync_config.source.connection_specification.with_indifferent_access
            initialize_client(connection_config)
            query = sync_config.model.query
            query = "#{query} LIMIT #{sync_config.limit}" unless sync_config.limit.nil?
            queried_data = @client.query(query)
            results = queried_data.map do |record|
              flatten_nested_hash(record)
            end
            results.map do |row|
              RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
            end
          rescue StandardError => e
            handle_exception(e, {
                               context: "SALESFORCE:CONSUMER:GOODS:ClOUD:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: sync_config.sync_id,
                               sync_run_id: sync_config.sync_run_id
                             })
          end

          private

          def query(connection, query)
            queried_data = connection.query(query)

            results = queried_data.map do |record|
              flatten_nested_hash(record)
            end
            results.map do |row|
              RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
            end
          end

          def flatten_nested_hash(record, prefix = nil)
            record = record.reject { |key, _| key == "attributes" }
            record.flat_map do |key, value|
              if value.is_a?(Hash)
                flatten_nested_hash(value, prefix ? "#{prefix}_#{key}" : key)
              else
                { prefix ? "#{prefix}_#{key}" : key => value }
              end
            end.reduce({}, :merge)
          end

          def create_connection(connection_config)
            initialize_client(connection_config)
          end

          def initialize_client(config)
            config = config.with_indifferent_access
            @client = Restforce.new(username: config[:username],
                                    password: config[:password] + config[:security_token],
                                    host: config[:host],
                                    client_id: config[:client_id],
                                    client_secret: config[:client_secret],
                                    api_version: API_VERSION)
          end

          def authenticate_client
            @client.authenticate!
          end

          def load_catalog
            read_json(CATALOG_SPEC_PATH)
          end

          def success_status
            ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
          end

          def failure_status(error)
            ConnectionStatus.new(status: ConnectionStatusType["failed"], message: error.message).to_multiwoven_message
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
