# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Destination
      module Airtable
        module SchemaHelper
          include Core::Constants

          module_function

          def clean_name(name_str)
            name_str.strip.gsub(" ", "_")
          end

          def get_json_schema(table)
            fields = table["fields"] || {}
            properties = fields.each_with_object({}) do |field, props|
              name, schema = process_field(field)
              props[name] = schema
            end

            build_schema(properties)
          end

          def process_field(field)
            name = clean_name(field.fetch("name", ""))
            original_type = field.fetch("type", "")
            options = field.fetch("options", {})

            schema = determine_schema(original_type, options)
            [name, schema]
          end

          def determine_schema(original_type, options)
            if COMPLEX_AIRTABLE_TYPES.keys.include?(original_type)
              complex_type = deep_copy(COMPLEX_AIRTABLE_TYPES[original_type])
              adjust_complex_type(original_type, complex_type, options)
            elsif SIMPLE_AIRTABLE_TYPES.keys.include?(original_type)
              simple_type_schema(original_type, options)
            else
              SCHEMA_TYPES[:STRING]
            end
          end

          def adjust_complex_type(original_type, complex_type, options)
            exec_type = options.dig("result", "type") || "simpleText"
            if complex_type == SCHEMA_TYPES[:ARRAY_WITH_ANY]
              adjust_array_with_any(original_type, complex_type, exec_type, options)
            else
              complex_type
            end
          end

          def adjust_array_with_any(original_type, complex_type, exec_type, options)
            if original_type == "formula" && %w[number currency percent duration].include?(exec_type)
              complex_type = SCHEMA_TYPES[:NUMBER]
            elsif original_type == "formula" && ARRAY_FORMULAS.none? { |x| options.fetch("formula", "").start_with?(x) }
              complex_type = SCHEMA_TYPES[:STRING]
            elsif SIMPLE_AIRTABLE_TYPES.keys.include?(exec_type)
              complex_type["items"] = deep_copy(SIMPLE_AIRTABLE_TYPES[exec_type])
            else
              complex_type["items"] = SCHEMA_TYPES[:STRING]
            end
            complex_type
          end

          def simple_type_schema(original_type, options)
            exec_type = options.dig("result", "type") || original_type
            deep_copy(SIMPLE_AIRTABLE_TYPES[exec_type])
          end

          def build_schema(properties)
            {
              "$schema" => JSON_SCHEMA_URL,
              "type" => "object",
              "additionalProperties" => true,
              "properties" => properties
            }
          end

          def deep_copy(object)
            Marshal.load(Marshal.dump(object))
          end

          SCHEMA_TYPES = {
            STRING: { "type": %w[null string] },
            NUMBER: { "type": %w[null number] },
            BOOLEAN: { "type": %w[null boolean] },
            DATE: { "type": %w[null string], "format": "date" },
            DATETIME: { "type": %w[null string], "format": "date-time" },
            ARRAY_WITH_STRINGS: { "type": %w[null array], "items": { "type": %w[null string] } },
            ARRAY_WITH_ANY: { "type": %w[null array], "items": {} }
          }.freeze.with_indifferent_access

          SIMPLE_AIRTABLE_TYPES = {
            "multipleAttachments" => SCHEMA_TYPES[:STRING],
            "autoNumber" => SCHEMA_TYPES[:NUMBER],
            "barcode" => SCHEMA_TYPES[:STRING],
            "button" => SCHEMA_TYPES[:STRING],
            "checkbox" => :BOOLEAN,
            "singleCollaborator" => SCHEMA_TYPES[:STRING],
            "count" => SCHEMA_TYPES[:NUMBER],
            "createdBy" => SCHEMA_TYPES[:STRING],
            "createdTime" => SCHEMA_TYPES[:DATETIME],
            "currency" => SCHEMA_TYPES[:NUMBER],
            "email" => SCHEMA_TYPES[:STRING],
            "date" => SCHEMA_TYPES[:DATE],
            "dateTime" => SCHEMA_TYPES[:DATETIME],
            "duration" => SCHEMA_TYPES[:NUMBER],
            "lastModifiedBy" => SCHEMA_TYPES[:STRING],
            "lastModifiedTime" => SCHEMA_TYPES[:DATETIME],
            "multipleRecordLinks" => SCHEMA_TYPES[:ARRAY_WITH_STRINGS],
            "multilineText" => SCHEMA_TYPES[:STRING],
            "multipleCollaborators" => SCHEMA_TYPES[:ARRAY_WITH_STRINGS],
            "multipleSelects" => SCHEMA_TYPES[:ARRAY_WITH_STRINGS],
            "number" => SCHEMA_TYPES[:NUMBER],
            "percent" => SCHEMA_TYPES[:NUMBER],
            "phoneNumber" => SCHEMA_TYPES[:STRING],
            "rating" => SCHEMA_TYPES[:NUMBER],
            "richText" => SCHEMA_TYPES[:STRING],
            "singleLineText" => SCHEMA_TYPES[:STRING],
            "singleSelect" => SCHEMA_TYPES[:STRING],
            "externalSyncSource" => SCHEMA_TYPES[:STRING],
            "url" => SCHEMA_TYPES[:STRING],
            "simpleText" => SCHEMA_TYPES[:STRING]
          }.freeze

          COMPLEX_AIRTABLE_TYPES = {
            "formula" => SCHEMA_TYPES[:ARRAY_WITH_ANY],
            "lookup" => SCHEMA_TYPES[:ARRAY_WITH_ANY],
            "multipleLookupValues" => SCHEMA_TYPES[:ARRAY_WITH_ANY],
            "rollup" => SCHEMA_TYPES[:ARRAY_WITH_ANY]
          }.freeze.with_indifferent_access

          ARRAY_FORMULAS = %w[ARRAYCOMPACT ARRAYFLATTEN ARRAYUNIQUE ARRAYSLICE].freeze
        end
      end
    end
  end
end
