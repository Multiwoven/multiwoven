# frozen_string_literal: true

module Api
  module V1
    class ModelsController < ApplicationController
      include Models
      attr_reader :connector, :model

      before_action :set_connector, only: %i[create]
      before_action :set_model, only: %i[show update destroy]
      before_action :validate_query, only: %i[create update]
      after_action :event_logger

      def index
        @models = current_workspace
                  .models.all.page(params[:page] || 1)
        render json: @models, status: :ok
      end

      def show
        render json: @model, status: :ok
      end

      def create
        result = CreateModel.call(
          connector:,
          model_params:
        )
        if result.success?
          @model = result.model
          render json: @model, status: :created
        else
          render_error(
            message: "Model creation failed",
            status: :unprocessable_entity,
            details: format_errors(result.model)
          )
        end
      end

      def update
        result = UpdateModel.call(
          model:,
          model_params:
        )

        if result.success?
          @model = result.model
          render json: @model, status: :ok
        else
          render_error(
            message: "Model update failed",
            status: :unprocessable_entity,
            details: format_errors(result.model)
          )
        end
      end

      def destroy
        model.destroy!
        head :no_content
      end

      private

      def set_connector
        @connector = current_workspace.connectors.find(model_params[:connector_id])
      end

      def set_model
        @model = current_workspace.models.find(params[:id])
      end

      def validate_query
        query = params.dig(:model, :query)
        return if query.blank?

        query_type = @model.present? ? @model.connector.connector_query_type : @connector.connector_query_type
        Utils::QueryValidator.validate_query(query_type, query)
      rescue StandardError => e
        render_error(
          message: "Query validation failed: #{e.message}",
          status: :unprocessable_entity
        )
      end

      def model_params
        params.require(:model).permit(:connector_id,
                                      :name,
                                      :description,
                                      :query,
                                      :query_type,
                                      :primary_key).merge(workspace_id: current_workspace.id)
      end
    end
  end
end
