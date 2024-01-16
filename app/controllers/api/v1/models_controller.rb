# frozen_string_literal: true

module Api
  module V1
    class ModelsController < ApplicationController
      include Models
      attr_reader :connector, :model

      before_action :set_connector, only: %i[create]
      before_action :set_model, only: %i[show update destroy]

      def index
        @models = current_workspace
                  .models.all.page(params[:page] || 1)
      end

      def show; end

      def create
        result = CreateModel.call(
          connector:,
          model_params:
        )

        if result.success?
          @model = result.model
        else
          render json: { errors: result.errors },
                 status: :unprocessable_entity
        end
      end

      def update
        result = UpdateModel.call(
          model:,
          model_params:
        )

        if result.success?
          @model = result.model
        else
          render json: { errors: result.errors },
                 status: :unprocessable_entity
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

      def model_params
        params.require(:model).permit(:connector_id,
                                      :name,
                                      :query,
                                      :query_type,
                                      :primary_key).merge(workspace_id: current_workspace.id)
      end
    end
  end
end
