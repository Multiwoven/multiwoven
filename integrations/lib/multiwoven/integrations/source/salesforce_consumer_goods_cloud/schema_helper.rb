# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Source
      module SalesforceConsumerGoodsCloud
        module SchemaHelper
          include Core::Constants

          module_function

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
              "supported_sync_modes": %w[incremental],
              "source_defined_primary_key": [primary_key],
              "source_defined_cursor": false,
              "default_cursor_field": nil
            }
          end
        end
      end
    end
  end
end
