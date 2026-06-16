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

          def discover(connection_config = nil)
            catalog = build_catalog(load_catalog)
            append_custom_object_streams(catalog, connection_config) if connection_config
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
              request, response = *send_data_to_hubspot(stream, record)
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

          def send_data_to_hubspot(stream, record = {})
            schema = stream.json_schema.with_indifferent_access
            object_type = schema[:hubspot_object_type]
            return upsert_custom_object(object_type, schema[:external_id_property], record) if object_type

            args = build_args(@action, stream.name, record)
            hubspot_stream = @client.crm.send(stream.name)
            hubspot_data = { simple_public_object_input_for_create: args }
            response = hubspot_stream.basic_api.send(@action, hubspot_data)
            [args, response]
          end

          # Custom objects are unreachable through `crm.send(stream_name)` (no such method);
          # they must go through the generic `crm.objects` API, keyed by object_type id.
          # gem 17.2.0 has no batch upsert-by-idProperty, so we upsert per record:
          # update by the unique external-id property, and create on a 404.
          def upsert_custom_object(object_type, external_id_property, record)
            input = { properties: record[:properties] || record }
            external_id = external_id_property && input[:properties] && input[:properties][external_id_property]

            if external_id_property && !external_id.to_s.empty?
              begin
                response = @client.crm.objects.basic_api.update(
                  object_type, external_id.to_s, input, id_property: external_id_property
                )
                return [input, response]
              rescue ::Hubspot::Crm::Objects::ApiError => e
                raise unless e.code == 404
                # Not found by external id → fall through and create it.
              end
            end

            response = @client.crm.objects.basic_api.create(object_type, input)
            [input, response]
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

          # Discover the portal's custom objects and expose one stream per object,
          # alongside the static standard streams. Failure here must not break the
          # discovery of the standard objects, so it is rescued and logged.
          def append_custom_object_streams(catalog, connection_config)
            initialize_client(connection_config.with_indifferent_access)
            schemas = @client.crm.schemas.core_api.get_all.results || []
            schemas.each do |schema|
              catalog.streams << build_stream(custom_object_stream(schema))
            end
          rescue StandardError => e
            log_debug("HUBSPOT:CRM:DISCOVER:CUSTOM_OBJECTS:SKIPPED #{e.message}")
          end

          def custom_object_stream(schema)
            {
              "name" => schema.name,
              # "update" is a placeholder kept within the StreamAction enum; the real
              # upsert (update-by-external-id, create on 404) lives in #upsert_custom_object,
              # which is selected by the presence of hubspot_object_type, not by this action.
              "action" => "update",
              "json_schema" => custom_object_json_schema(schema),
              "supported_sync_modes" => %w[incremental],
              "batch_support" => false,
              "batch_size" => 1
            }
          end

          # hubspot_object_type and external_id_property are carried INSIDE json_schema
          # on purpose: build_stream and the server's stream_to_protocol both drop
          # unknown top-level stream keys, but json_schema is a free-form hash that
          # survives the round-trip back to #write.
          def custom_object_json_schema(schema)
            object_properties = Array(schema.properties).each_with_object({}) do |property, acc|
              acc[property.name] = { "type" => json_type_for(property.type) }
            end
            {
              "$schema" => "http://json-schema.org/draft-07/schema#",
              "title" => schema.labels&.singular || schema.name,
              "type" => "object",
              "hubspot_object_type" => schema.object_type_id,
              "external_id_property" => detect_external_id_property(schema),
              "properties" => {
                "properties" => {
                  "type" => "object",
                  "properties" => object_properties,
                  "additionalProperties" => { "type" => %w[string number boolean] }
                }
              }
            }
          end

          # The match key for upsert: the property flagged unique in HubSpot. When a
          # schema has several, prefer one that is also required (the canonical id).
          def detect_external_id_property(schema)
            unique = Array(schema.properties).select(&:has_unique_value)
            return if unique.empty?

            required = Array(schema.required_properties)
            (unique.find { |property| required.include?(property.name) } || unique.first).name
          end

          def json_type_for(hubspot_type)
            case hubspot_type
            when "number" then "number"
            when "bool" then "boolean"
            else "string"
            end
          end

          def log_debug(message)
            Multiwoven::Integrations::Service.logger.debug(message)
          end
        end
      end
    end
  end
end
