# frozen_string_literal: true

# app/controllers/api/v1/workspaces_controller.rb
module Api
  module V1
    class WorkspacesController < ApplicationController
      include Workspaces

      skip_before_action :validate_contract

      def index
        result = ListAll.call(user: current_user)
        @workspaces = result.workspaces
        render json: @workspaces, status: :ok
      end

      def create
        result = Create.call(user: current_user, workspace_params:)
        if result.success?
          @workspace = result.workspace
          render json: result.workspace, status: :created
        else
          render_error(
            message: "Workspace creation failed",
            status: :unprocessable_entity,
            details: format_errors(result.workspace)
          )
        end
      end

      def update
        result = Update.call(id: params[:id], user: current_user, workspace_params:)
        if result.success?
          @workspace = result.workspace
          render json: @workspace, status: :ok
        else
          render_error(
            message: "Workspace update failed",
            status: :unprocessable_entity,
            details: format_errors(result.workspace)
          )
        end
      end

      def destroy
        result = Workspaces::Delete.call(id: params[:id], user: current_user)

        if result.success?
          head :no_content
        else
          render_error(
            message: "Workspace delete failed",
            status: :unprocessable_entity,
            details: format_errors(result.workspace)
          )
        end
      end

      private

      def workspace_params
        params.require(:workspace).permit(:name, :organization_id)
      end
    end
  end
end
