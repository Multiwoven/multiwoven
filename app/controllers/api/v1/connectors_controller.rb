# frozen_string_literal: true

module Api
  module V1
    class ConnectorsController < ApplicationController
      include Connectors
      before_action :set_connector, only: %i[show update destroy]

      def index
        @connectors = current_workspace
                      .connectors.all.page(params[:page] || 1)
      end

      def show; end

      def create
        result = CreateConnector.call(
          workspace: current_workspace,
          connector_params:
        )

        if result.success?
          @connector = result.connector
        else
          render json: { errors: result.errors },
                 status: :unprocessable_entity
        end
      end

      def update
        result = UpdateConnector.call(
          connector: @connector,
          connector_params:
        )

        if result.success?
          @connector = result.connector
        else
          render json: { errors: result.errors },
                 status: :unprocessable_entity
        end
      end

      def destroy
        @connector.destroy!
        head :no_content
      end

      # TODO: connector config API
      # def config; end

      private

      def set_connector
        @connector = current_workspace.connectors.find(params[:id])
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: e.message }, status: :not_found
      end

      def connector_params
        params.require(:connector).permit(:workspace_id,
                                          :connector_definition_id,
                                          :connector_type, :name,
                                          configuration: {})
      end
    end
  end
end
