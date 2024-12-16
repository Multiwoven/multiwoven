# frozen_string_literal: true

module Api
  module V1
    # rubocop:disable Metrics/ClassLength
    class ConnectorsController < ApplicationController
      include Connectors
      include AuditLogger
      include ResourceLinkBuilder
      before_action :set_connector, only: %i[show update destroy discover query_source]
      # TODO: Enable this once we have query validation implemented for all the connectors
      # before_action :validate_query, only: %i[query_source]
      # TODO: Enable this for ai_ml sources
      before_action :validate_catalog, only: %i[query_source]
      after_action :event_logger
      after_action :create_audit_log, only: %i[create update destroy query_source]

      def index
        @connectors = current_workspace.connectors
        authorize @connectors
        @connectors = @connectors.send(params[:type].downcase) if params[:type]
        @connectors = @connectors.send(params[:category].downcase) if params[:category]
        @connectors = @connectors.page(params[:page] || 1)
        render json: @connectors, status: :ok
      end

      def show
        authorize @connector
        @audit_resource = @connector.name
        render json: @connector, status: :ok
      end

      def create
        authorize current_workspace, policy_class: ConnectorPolicy

        result = CreateConnector.call(
          workspace: current_workspace,
          connector_params:
        )
        if result.success?
          @connector = result.connector
          @audit_resource = @connector.name
          @resource_id = @connector.id
          @payload = connector_params
          render json: @connector, status: :created
        else
          render_error(
            message: result.error || "Connector creation failed",
            status: :unprocessable_entity,
            details: result.connector ? format_errors(result.connector) : nil
          )
        end
      end

      def update
        authorize @connector
        result = UpdateConnector.call(
          connector: @connector,
          connector_params:
        )

        if result.success?
          @connector = result.connector
          @audit_resource = @connector.name
          @payload = connector_params
          render json: @connector, status: :ok
        else
          render_error(
            message: "Connector update failed",
            status: :unprocessable_entity,
            details: format_errors(result.connector)
          )
        end
      end

      def destroy
        authorize @connector
        @action = "delete"
        @audit_resource = @connector.name
        @connector.destroy!
        head :no_content
      end

      def discover
        authorize @connector
        result = DiscoverConnector.call(
          connector: @connector,
          refresh: params[:refresh]
        )

        if result.success?
          @catalog = result.catalog
          @audit_resource = @connector.name
          @payload = @catalog
          render json: @catalog, status: :ok
        else
          render_error(
            message: "Discover catalog failed",
            status: :unprocessable_entity,
            details: format_errors(result.catalog)
          )
        end
      end

      def query_source
        authorize @connector
        if @connector.source?
          result = QuerySource.call(
            connector: @connector,
            query: params[:query],
            limit: params[:limit] || 50
          )

          if result.success?
            @records = result.records.map(&:record).map(&:data)
            @audit_resource = @connector.name
            @payload = @records
            render json: { data: @records }, status: :ok
          else
            render_error(
              message: result["error"],
              status: :unprocessable_entity
            )
          end
        else
          render_error(
            message: "Connector is not a source",
            status: :unprocessable_entity
          )
        end
      end

      private

      def set_connector
        @connector = current_workspace.connectors.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error(
          message: "Connector not found",
          status: :not_found
        )
      end

      def validate_catalog
        return unless @connector.ai_model?
        return if @connector.catalog.present?

        render_error(
          message: "Catalog is not present for the connector",
          status: :unprocessable_entity
        )
      end

      def validate_query
        Utils::QueryValidator.validate_query(@connector.connector_query_type, params[:query])
      rescue StandardError => e
        render_error(
          message: "Query validation failed: #{e.message}",
          status: :unprocessable_entity
        )
      end

      def create_audit_log
        resource_id = @resource_id || params[:id]
        resource_link = @action == "delete" ? nil : build_link!(resource: @connector, resource_id:)
        audit!(action: @action, resource_id:, resource: @audit_resource, payload: @payload, resource_link:)
      end

      def connector_params
        params.require(:connector).permit(:workspace_id,
                                          :connector_type,
                                          :connector_name, :name, :description, :query_type,
                                          configuration: {})
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
