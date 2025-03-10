# frozen_string_literal: true

# app/controllers/api/v1/workspaces_controller.rb
module Api
  module V1
    class WorkspacesController < ApplicationController
      include Workspaces
      include AuditLogger
      include ResourceLinkBuilder
      skip_after_action :verify_authorized, only: %i[index show]
      after_action :create_audit_log, only: %i[create update]

      def index
        result = ListAll.call(user: current_user)
        @workspaces = result.workspaces
        render json: @workspaces, status: :ok
      end

      def show
        result = Find.call(id: params[:id], user: current_user)
        if result.workspace
          @workspace = result.workspace
          render json: @workspace, status: :ok
        else
          render_error(
            message: "Workspace not found",
            status: :not_found
          )
        end
      end

      def create
        authorize current_workspace, policy_class: WorkspacePolicy
        result = Create.call(user: current_user, workspace_params:)
        if result.success?
          @workspace = result.workspace
<<<<<<< HEAD
=======
          @audit_resource = @workspace.name
          @resource_id = @workspace.id
          @payload = workspace_params
          authorize @workspace
>>>>>>> cd1bbac5 (chore(CE): Add Audit to Workspace Controller (#913))
          render json: result.workspace, status: :created
        else
          render_error(
            message: "Workspace creation failed",
            status: :unprocessable_content,
            details: format_errors(result.workspace)
          )
        end
      end

      def update
        authorize current_workspace, policy_class: WorkspacePolicy
        result = Update.call(id: params[:id], user: current_user, workspace_params:)
        if result.success?
          @workspace = result.workspace
<<<<<<< HEAD
=======
          @audit_resource = @workspace.name
          @payload = workspace_params
          authorize @workspace
>>>>>>> cd1bbac5 (chore(CE): Add Audit to Workspace Controller (#913))
          render json: @workspace, status: :ok
        else
          render_error(
            message: "Workspace update failed",
            status: :unprocessable_content,
            details: format_errors(result.workspace)
          )
        end
      end

      def destroy
        authorize current_workspace, policy_class: WorkspacePolicy
        action = "delete"
        resource = current_user.workspaces.find_by(id: params[:id]).name
        audit!(action:, resource_id: params[:id], resource:)
        result = Workspaces::Delete.call(id: params[:id], user: current_user)
        if result.success?
          head :no_content
        else
          render_error(
            message: "Workspace delete failed",
            status: :unprocessable_content,
            details: format_errors(result.workspace)
          )
        end
      end

      private

      def create_audit_log
        resource_id = @resource_id || params[:id]
        resource_link = build_link!(resource_id:)
        audit!(action: @action, resource_id:, resource: @audit_resource, payload: @payload, resource_link:)
      end

      def workspace_params
        params.require(:workspace).permit(:name, :organization_id, :description, :region)
      end
    end
  end
end
