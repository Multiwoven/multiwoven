# frozen_string_literal: true

module Api
  module V1
    class CatalogsController < ApplicationController
      include Catalogs
      before_action :set_connector, only: %i[create update]
      before_action :set_catalog, only: %i[update]

      def create
        authorize current_workspace, policy_class: ConnectorPolicy
        result = CreateCatalog.call(
          connector: @connector,
          catalog_params: catalog_params.to_h
        )

        if result.success?
          @catalog = result.catalog
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

      def catalog_params
        params.require(:catalog).permit(json_schema: {})
      end
    end
  end
end
