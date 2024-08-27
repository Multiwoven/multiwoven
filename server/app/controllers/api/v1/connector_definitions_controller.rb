# frozen_string_literal: true

module Api
  module V1
    class ConnectorDefinitionsController < ApplicationController
      include ConnectorDefinitions
      before_action :set_connectors, only: %i[show index]
      before_action :set_connector_client, only: %i[check_connection]

      def index
        authorize @connectors, policy_class: ConnectorDefinitionPolicy
        render json: @connectors
      end

      def show
        authorize @connectors, policy_class: ConnectorDefinitionPolicy
        @connector = @connectors.find do |hash|
          hash[:name].downcase == params[:id].downcase
        end
        render json: @connector || []
      end

      def check_connection
        connection_spec = params[:connection_spec]
        authorize connection_spec, policy_class: ConnectorDefinitionPolicy
        connection_spec = connection_spec.to_unsafe_h if connection_spec.respond_to?(:to_unsafe_h)
        connection_status = @connector_client
                            .check_connection(
                              connection_spec
                            )
        render json: connection_status
      end

      private

      def set_connectors
        @connectors = FilterConnectors.call(
          connection_definitions_params
        ).connectors
      end

      def set_connector_client
        @connector_client = Multiwoven::Integrations::Service
                            .connector_class(
                              params[:type].camelize,
                              params[:name].camelize
                            ).new
      end

      def connection_definitions_params
        params.permit(:type, :category)
      end
    end
  end
end
