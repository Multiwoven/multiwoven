# frozen_string_literal: true

module Api
  module V1
    class CatalogsController < ApplicationController
      include Catalogs
      include AuditLogger
      include ResourceLinkBuilder
      before_action :set_connector, only: %i[create update]
      before_action :set_catalog, only: %i[update]

      after_action :create_audit_log

      def create
        authorize current_workspace, policy_class: ConnectorPolicy
        result = CreateCatalog.call(
          connector: @connector,
          catalog_params: catalog_params.to_h
        )

        if result.success?
          @catalog = result.catalog
          @audit_resource = @catalog.catalog["streams"].first["name"]
          @payload = catalog_params.to_h
          render json: @catalog, status: :created
        else
          render_error(
            message: "Catalog creation failed",
            status: :unprocessable_entity,
            details: format_errors(result.catalog)
          )
        end
      end

      def update
        authorize current_workspace, policy_class: ConnectorPolicy
        result = UpdateCatalog.call(
          connector: @connector,
          catalog: @catalog,
          catalog_params: catalog_params.to_h
        )

        if result.success?
          @catalog = result.catalog
          @audit_resource = @catalog.catalog["streams"].first["name"]
          @payload = catalog_params.to_h
          render json: @catalog, status: :created
        else
          render_error(
            message: "Catalog update failed",
            status: :unprocessable_entity,
            details: format_errors(result.catalog)
          )
        end
      end

      private

      def set_connector
        @connector = current_workspace.connectors.find(params[:connector_id])
      rescue ActiveRecord::RecordNotFound
        render_error(
          message: "Connector not found",
          status: :not_found
        )
      end

      def set_catalog
        @catalog = @connector.catalog
      end

      def create_audit_log
        resource_id = params[:id] || params[:connector_id]
        resource_link = build_link!(resource: @connector, resource_id: params[:connector_id])
        audit!(resource_id:, resource: @audit_resource, payload: @payload, resource_link:)
      end

      def catalog_params
        params.require(:catalog).permit(json_schema: {})
      end
    end
  end
end
