# frozen_string_literal: true

module Api
  module V1
    class ConnectorsController < ApplicationController
      include Connectors
      before_action :set_connector, only: %i[show update destroy discover query_source]
      # TODO: Enable this once we have query validation implemented for all the connectors
      # before_action :validate_query, only: %i[query_source]
      after_action :event_logger

      def index
        @connectors = current_workspace.connectors
        authorize @connectors
        @connectors = @connectors.send(params[:type].downcase) if params[:type]
        @connectors = @connectors.page(params[:page] || 1)
        render json: @connectors, status: :ok
      end

      def show
        authorize @connector
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
        authorize @connector
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
        authorize @connector
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

      def validate_query
        Utils::QueryValidator.validate_query(@connector.connector_query_type, params[:query])
      rescue StandardError => e
        render_error(
          message: "Query validation failed: #{e.message}",
          status: :unprocessable_entity
        )
      end

      def connector_params
        params.require(:connector).permit(:workspace_id,
                                          :connector_type,
                                          :connector_name, :name, :description, :query_type,
                                          configuration: {})
      end
    end
  end
end
