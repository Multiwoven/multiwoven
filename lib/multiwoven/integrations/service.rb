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
            source: build_connectors(ENABLED_SOURCES, "Source"),
            destination: build_connectors(ENABLED_DESTINATIONS, "Destination")
          }
        end

        def connector_class(connector_type, connector_name)
          Object.const_get("Multiwoven::Integrations::#{connector_type}::#{connector_name}::Client")
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
            connector_class(
              type, connector
            ).new.meta_data
          end
        end

        def default_logger
          @default_logger ||= Logger.new($stdout)
        end
      end
    end
  end
end
