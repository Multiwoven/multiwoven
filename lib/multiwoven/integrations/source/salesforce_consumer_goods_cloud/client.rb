# frozen_string_literal: true

require "stringio"

module Multiwoven
  module Integrations
    module Source
      module SalesforceConsumerGoodsCloud
        include Multiwoven::Integrations::Core

        API_VERSION = "59.0"
        SALESFORCE_OBJECTS = %w[Account User Visit RetailStore].freeze

        class Client < SourceConnector # rubocop:disable Metrics/ClassLength
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
              streams << JSON.parse(create_json_schema_for_object(object_description).to_json)
            end
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception("SALESFORCE:CRM:DISCOVER:EXCEPTION", "error", e)
          end

          def read(sync_config)
            connection_config = sync_config.source.connection_specification.with_indifferent_access
            initialize_client(connection_config)
            query = sync_config.model.query
            query = batched_query(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
            exclude_keys = ["attributes"]
            queried_data = @client.query(query)
            results = queried_data.map do |record|
              record.reject { |key, _| exclude_keys.include?(key) }
            end
            results.map do |row|
              RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
            end
          rescue StandardError => e
            handle_exception("SALESFORCE:CRM:WRITE:EXCEPTION", "error", e)
          end

          private

          def query(connection, query)
            exclude_keys = ["attributes"]
            queried_data = connection.query(query)
            results = queried_data.map do |record|
              record.reject { |key, _| exclude_keys.include?(key) }
            end
            results.map do |row|
              RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
            end
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

          def salesforce_field_to_json_schema_type(sf_field) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
            case sf_field["type"]
            when "string", "Email", "Phone", "Text", "TextArea", "TextEncrypted", "URL", "Picklist (Single)"
              if sf_field["nillable"]
                { "type": %w[string null] }
              else
                { "type": "string" }
              end
            when "double", "Currency", "Percent"
              if sf_field["nillable"]
                { "type": %w[number null] }
              else
                { "type": "number" }
              end
            when "boolean", "Checkbox"
              if sf_field["nillable"]
                { "type": %w[boolean null] }
              else
                { "type": "boolean" }
              end
            when "int", "AutoNumber"
              if sf_field["nillable"]
                { "type": %w[integer null] }
              else
                { "type": "integer" }
              end
            when "date"
              if sf_field["nillable"]
                { "type": %w[string null], "format": "date" }
              else
                { "type": "string", "format": "date" }
              end
            when "datetime", "DateTime"
              if sf_field["nillable"]
                { "type": %w[string null], "format": "date-time" }
              else
                { "type": "string", "format": "date-time" }
              end
            when "time"
              if sf_field["nillable"]
                { "type": %w[string null], "format": "time" }
              else
                { "type": "string", "format": "time" }
              end
            when "textarea", "Text Area (Long)", "Text Area (Rich)"
              if sf_field["nillable"]
                { "type": %w[string null] }
              else
                { "type": "string" }
              end
            when "picklist", "multipicklist", "Picklist (Multi-select)"
              if sf_field[:picklistValues] && sf_field["nillable"]
                enum_values = sf_field[:picklistValues].map { |val| val["value"] }
                { "type": %w[array null], "items": { "type": "string" }, "enum": enum_values }
              elsif sf_field[:picklistValues]
                enum_values = sf_field[:picklistValues].map { |val| val["value"] }
                { "type": "array", "items": { "type": "string" }, "enum": enum_values }
              else
                { "type": "array", "items": { "type": "string" } }
              end
            when "reference", "Reference (Lookup & Master-Detail)"
              if sf_field["nillable"]
                { "type": %w[string null] }
              else
                { "type": "string" }
              end
            when "location", "Geolocation"
              if sf_field["nillable"]
                { "type": %w[object null], "properties": { "latitude": { "type": "number" }, "longitude": { "type": "number" } } }
              else
                { "type": "object", "properties": { "latitude": { "type": "number" }, "longitude": { "type": "number" } } }
              end
            else
              if sf_field["nillable"]
                { "type": %w[string null] }
              else
                { "type": "string" }
              end
            end
          end

          def create_json_schema_for_object(metadata)
            fields_schema = metadata["fields"].map do |field|
              {
                "#{field[:name]}": salesforce_field_to_json_schema_type(field)
              }
            end.reduce(:merge)

            json_schema = {
              "$schema": "http://json-schema.org/draft-07/schema#",
              "title": metadata["name"],
              "type": "object",
              "additionalProperties": true,
              "properties": fields_schema
            }

            required = metadata["fields"].map do |field|
              field["name"] if field["nillable"] == false
            end.compact
            primary_key = metadata["fields"].map do |field|
              field["name"] if field["nillable"] == false && field["unique"] == true
            end.compact

            {
              "name": metadata["name"],
              "action": "create",
              "json_schema": json_schema,
              "required": required,
              "supported_sync_modes": %w[full_refresh incremental],
              "source_defined_cursor": true,
              "default_cursor_field": ["updated"],
              "source_defined_primary_key": [primary_key]
            }
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
