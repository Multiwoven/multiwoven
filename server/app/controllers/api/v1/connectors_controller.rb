# frozen_string_literal: true

module Api
  module V1
    class ConnectorsController < ApplicationController
      include Connectors
      before_action :set_connector, only: %i[show update destroy discover query_source]
      after_action :event_logger

      def index
        @connectors = current_workspace.connectors
        @connectors = @connectors.send(params[:type].downcase) if params[:type]
        @connectors = @connectors.page(params[:page] || 1)
        render json: @connectors, status: :ok
      end

      def show
        render json: @connector, status: :ok
      end

      def create
        result = CreateConnector.call(
          workspace: current_workspace,
          connector_params:
        )

        if result.success?
          @connector = result.connector
          render json: @connector, status: :created
        else
          render_error(
            message: "Connector creation failed",
            status: :unprocessable_entity,
            details: format_errors(result.connector)
          )
        end
      end

      def update
        result = UpdateConnector.call(
          connector: @connector,
          connector_params:
        )

        if result.success?
          @connector = result.connector
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
        @connector.destroy!
        head :no_content
      end

      def discover
        result = DiscoverConnector.call(
          connector: @connector
        )

        if result.success?
          @catalog = result.catalog
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
        if @connector.source?
          result = QuerySource.call(
            connector: @connector,
            query: params[:query],
            limit: params[:limit] || 50
          )

          if result.success?
            @records = result.records.map(&:record).map(&:data)
            render json: @records, status: :ok
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

      def connector_params
        params.require(:connector).permit(:workspace_id,
                                          :connector_type,
                                          :connector_name, :name, :description,
                                          configuration: {})
      end
    end
  end
end
