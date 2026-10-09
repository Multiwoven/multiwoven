# frozen_string_literal: true

module Multiwoven
  module Integrations
    class Service
      def initialize
        yield(self.class.config) if block_given?
      end
      class << self
        # deep_dup, not dup: the entries are the clients' own memoized metadata, so a
        # shallow copy lets one caller's mutation reach every later caller.
        def connectors
          built = built_connectors
          { source: built[:source].deep_dup, destination: built[:destination].deep_dup }
        end

        # The build is memoized for the life of the process, so anything that
        # changes what would be built has to clear it.
        def reset_connectors!
          @built_connectors = nil
        end

        def connector_class(connector_type, connector_name)
          Object.const_get(
            "Multiwoven::Integrations::#{connector_type}::#{connector_name}::Client"
          )
        end

        def logger
          config.logger || default_logger
        end

        def exception_reporter
          config.exception_reporter
        end

        def config
          @config ||= Config.new
        end

        private

        def built_connectors
          @built_connectors ||= {
            source: build_connectors(ENABLED_SOURCES, "Source"),
            destination: build_connectors(ENABLED_DESTINATIONS, "Destination")
          }
        end

        def build_connectors(enabled_connectors, type)
          enabled_connectors.map do |connector|
            client = connector_class(type, connector).new
            client.meta_data[:data][:connector_spec] = client.connector_spec.to_h
            client.meta_data[:data]
          end
        end

        def default_logger
          @default_logger ||= Logger.new($stdout)
        end
      end
    end
  end
end
