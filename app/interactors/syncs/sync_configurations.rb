# frozen_string_literal: true

module Syncs
  class SyncConfigurations
    include Interactor

    def call
      context.configurations = configurations
    end

    private

    def configurations
      {
        data: {
          configurations: {
            catalog_mapping_types:
          }
        }
      }
    end

    def catalog_mapping_types
      {
        standard: "",
        static: static_configuration,
        template: {
          variable: template_variables,
          filter: template_filters
        }
      }
    end

    def static_configuration
      {
        string: {
          type: "string",
          description: "Strings can include any combination of numbers, letters, and special characters."
        },
        number: {
          type: "float",
          description: "Number can be any numerical value as integer or float"
        },
        boolean: {
          type: "boolean",
          description: "true or false value will be synced to this destination field."
        },
        null: {
          type: "null",
          description: "A null value will be synced to this destination field."
        }
      }
    end

    def template_variables
      {
        current_timestamp: {
          type: "datetime",
          description: "The current timestamp as an ISO 8601 string YYYY-MM-DDTHH:mm:ss.sssZ.",
          value: "{{ 'now' | date: '%Y-%m-%dT%H:%M:%S.%L%z' }}"
        }
      }
    end

    def template_filters
      {
        cast: {
          description: "Cast input to specified type. Supported values: string, number, boolean",
          value: "{{ cast: '<string>' }}"
        },
        regex_replace: {
          description: "Search and replace substrings of input using RegEx",
          value: "{{ regex_replace : '<[a-zA-Z]>', '<replacement>', '<flags>' }}"
        }
      }
    end
  end
end
