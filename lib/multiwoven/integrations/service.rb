# frozen_string_literal: true

module Multiwoven
  module Integrations
    class Service
      class << self
        def initialize
          yield(config) if block_given?
        end

        def connectors
          {
            source: build_connectors(
              ENABLED_SOURCES, "Source"
            ),
            destination: build_connectors(
              ENABLED_DESTINATIONS, "Destination"
            )
          }
        end

        def connector_class(connector_type, connector_name)
          Object.const_get(
            "Multiwoven::Integrations::#{connector_type}::#{connector_name}::Client"
          )
        end

        def logger
          config.logger || default_logger
        end

        def config
          @config ||= Config.new
        end

        private

        def build_connectors(enabled_connectors, type)
          enabled_connectors.map do |connector|
            client = connector_class(
              type, connector
            ).new
            client.meta_data["data"].to_h.merge(
              {
                connector_spec: client.connector_spec.to_h
              }
            )
          end
        end

        def default_logger
          @default_logger ||= Logger.new($stdout)
        end
      end
    end
  end
end
