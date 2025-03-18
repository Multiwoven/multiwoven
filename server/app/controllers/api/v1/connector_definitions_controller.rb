# frozen_string_literal: true

module Api
  module V1
    class ConnectorDefinitionsController < ApplicationController
      include ConnectorDefinitions
      include AuditLogger
      before_action :set_connectors, only: %i[show index]
      before_action :set_connector_client, only: %i[check_connection]
      after_action :create_audit_log, only: %i[check_connection]

      def index
        authorize @connectors, policy_class: ConnectorDefinitionPolicy
        render json: @connectors
      end

      def show
        authorize @connectors, policy_class: ConnectorDefinitionPolicy
        @connector = @connectors.find do |hash|
          hash[:name].downcase == params[:id].downcase
        end
        @audit_resource = @connector&.[](:name)
        render json: @connector || []
      end

      def check_connection
        connection_spec = params[:connection_spec]
        authorize connection_spec, policy_class: ConnectorDefinitionPolicy
        connection_spec = connection_spec.to_unsafe_h if connection_spec.respond_to?(:to_unsafe_h)

        begin
          connection_status = @connector_client
                              .check_connection(
                                connection_spec
                              )
          @audit_resource = params[:name]
          render json: connection_status
        rescue => e
          render json: { error: e.message }, status: :internal_server_error
        end
      end

      private

      def set_connectors
        @connectors = FilterConnectorDefinitions.call(
          connection_definitions_params
        ).connectors
      end

      def set_connector_client
        begin
          connector_class = Multiwoven::Integrations::Service
                            .connector_class(
                              params[:type].camelize,
                              params[:name]
                            )
          @connector_client = connector_class.new
        rescue => e
          raise e
        end
      end

      def create_audit_log
        audit!(resource_id: params[:id], resource: @audit_resource, payload: @payload)
      end

      def connection_definitions_params
        params.permit(:type, :category)
      end
    end
  end
end
