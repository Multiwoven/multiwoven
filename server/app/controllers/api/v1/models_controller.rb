# frozen_string_literal: true

module Api
  module V1
    class ModelsController < ApplicationController
      include Models
      include AuditLogger
      include ResourceLinkBuilder
      attr_reader :connector, :model

      before_action :set_connector, only: %i[create]
      before_action :set_model, only: %i[show update destroy]
      before_action :validate_catalog, only: %i[create update]
      # TODO: Enable this once we have query validation implemented for all the connectors
      # before_action :validate_query, only: %i[create update]
      after_action :event_logger
      after_action :create_audit_log, only: %i[create update destroy]

      def index
        query_type = request.query_parameters["query_type"].try(:split, ",")
        workspace_models = current_workspace.models.page(params[:page] || 1).per(params[:per_page])
        @models = query_type ? workspace_models.where(query_type:) : workspace_models
        authorize @models
        render json: @models, status: :ok
      end

      def show
        authorize @model
        @audit_resource = @model.name
        render json: @model, status: :ok
      end

      def create
        authorize current_workspace, policy_class: ModelPolicy
        result = CreateModel.call(
          connector:,
          model_params:
        )
        if result.success?
          @model = result.model
          @audit_resource = @model.name
          @resource_id = @model.id
          @payload = model_params
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
        authorize model
        result = UpdateModel.call(
          model:,
          model_params:
        )

        if result.success?
          @model = result.model
          @audit_resource = @model.name
          @payload = model_params
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
        authorize model
        @action = "delete"
        @audit_resource = model.name
        model.destroy!
        head :no_content
      end

      private

      def set_connector
        @connector = current_workspace.connectors.find(model_params[:connector_id])
      end

      def set_model
        @model = current_workspace.models.find(params[:id])
        @connector = @model.connector
      end

      def validate_catalog
        return unless connector.ai_model?
        return if connector.catalog.present?

        render_error(
          message: "Catalog is not present for the connector",
          status: :unprocessable_entity
        )
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

      def create_audit_log
        resource_id = @resource_id || params[:id]
        resource_link = @action == "delete" ? nil : build_link!(resource: @model, resource_id:)
        audit!(action: @action, resource_id:, resource: @audit_resource, payload: @payload, resource_link:)
      end

      def model_params
        params.require(:model).permit(
          :connector_id,
          :name,
          :description,
          :query,
          :query_type,
          :primary_key,
          configuration: {}
        ).merge(
          workspace_id: current_workspace.id
        )
      end
    end
  end
end
