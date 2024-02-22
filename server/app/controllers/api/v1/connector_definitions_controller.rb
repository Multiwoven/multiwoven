# frozen_string_literal: true

module Api
  module V1
    class ConnectorDefinitionsController < ApplicationController
      before_action :set_connectors, only: %i[show index]
      before_action :set_connector_client, only: %i[check_connection]

      def index
        render json: @connectors
      end

      def show
        @connector = @connectors.find do |hash|
          hash[:name].downcase == params[:id].downcase
        end
        render json: @connector || []
      end

      def check_connection
        connection_spec = params[:connection_spec]
        connection_spec = connection_spec.to_unsafe_h if connection_spec.respond_to?(:to_unsafe_h)
        connection_status = @connector_client
                            .check_connection(
                              connection_spec
                            )

        render json: connection_status
      end

      private

      def set_connectors
        @connectors = Multiwoven::Integrations::Service
                      .connectors
                      .with_indifferent_access
        @connectors = @connectors[params[:type]] if params[:type]
      end

      def set_connector_client
        @connector_client = Multiwoven::Integrations::Service
                            .connector_class(
                              params[:type].camelize,
                              params[:name].camelize
                            ).new
      end
    end
  end
end
