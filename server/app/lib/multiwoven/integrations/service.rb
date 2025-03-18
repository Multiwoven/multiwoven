# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Service
      # This is a custom implementation to load connector classes without relying on the multiwoven-integrations gem
      # It specifically handles the GoogleCloudStorage connector
      
      # Load the connector class based on type and name
      def self.connector_class(type, name)
        if type.to_s.downcase == "source" && name.to_s.downcase == "googlecloudstorage"
          # Return our custom GoogleCloudStorage client implementation
          # Make sure we're using the Client class from client.rb, not rest_client.rb
          Rails.logger.info "Loading custom GoogleCloudStorage Client implementation"
          Multiwoven::Integrations::Source::GoogleCloudStorage::Client
        else
          # For other connectors, delegate to the gem
          # This is just a fallback - in a complete implementation, 
          # you would handle all connectors you want to use directly
          begin
            require 'multiwoven-integrations'
            # Use the gem's implementation for other connectors
            ::Multiwoven::Integrations::Service.connector_class(type, name)
          rescue LoadError => e
            Rails.logger.error "Error loading multiwoven-integrations gem: #{e.message}"
            raise "Connector #{type}/#{name} is not available without the multiwoven-integrations gem"
          end
        end
      end
      
      # Return a list of available connectors
      # This is used by the FilterConnectorDefinitions interactor
      def self.connectors
        begin
          require 'multiwoven-integrations'
          # Get connectors from the gem
          ::Multiwoven::Integrations::Service.connectors
        rescue LoadError => e
          Rails.logger.error "Error loading multiwoven-integrations gem: #{e.message}"
          # Return a minimal set of connectors if the gem is not available
          {
            source: [],
            destination: []
          }
        end
      end
    end
  end
end
