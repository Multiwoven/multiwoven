# frozen_string_literal: true

module Api
  module V1
    class WorkspaceUsersController < ApplicationController
      include WorkspaceUsers
      before_action :set_workspace
      before_action :authorize_admin!, except: [:index]

      # POST /api/v1/workspaces/:workspace_id/workspace_users
      def create
        result = Create.call(workspace: @workspace, user_params: workspace_user_params)

        if result.success?
          @workspace_user = result.workspace_user
          render json: @workspace_user, status: :created
        else
          render_error(
            message: "Workspace User creation failed",
            status: :unprocessable_entity,
            details: format_errors(result.workspace_user)
          )
        end
      end

      # GET /api/v1/workspaces/:workspace_id/workspace_users
      def index
        result = List.call(workspace: @workspace)
        @workspace_users = result.workspace_users
        render json: @workspace_users, status: :ok
      end

      # PUT /api/v1/workspaces/:workspace_id/workspace_users/:id
      def update
        result = Update.call(id: params[:id], role: workspace_user_params[:role])

        if result.success?
          @workspace_user = result.workspace_user
          render json: @workspace_user, status: :ok
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/workspaces/:workspace_id/workspace_users/:id
      def destroy
        result = Delete.call(id: params[:id])

        if result.success?
          head :no_content
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_workspace
        @workspace = current_user.workspaces.find(params[:workspace_id])
      end

      def authorize_admin!
        workspace_user = current_user.workspace_users.find_by(workspace: @workspace)
        return if workspace_user.admin?

        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def workspace_user_params
        params.require(:workspace_user).permit(:email, :role, :name)
      end
    end
  end
end
