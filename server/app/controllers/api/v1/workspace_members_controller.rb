# frozen_string_literal: true

module Api
  module V1
    class WorkspaceMembersController < ApplicationController
      # Skip contract validation since we don't have a WorkspaceMemberContracts class
      skip_before_action :validate_contract
      # Skip the exception handler since we're handling errors directly
      skip_around_action :handle_with_exception
      # Skip Pundit's authorization verification since we have custom authorization
      skip_after_action :verify_authorized
      
      before_action :authenticate_user!
      before_action :set_workspace
      before_action :authorize_admin, only: [:create]

      # GET /api/v1/workspaces/:workspace_id/members
      def index
        @members = @workspace.workspace_users.includes(:user, :role)
        render json: {
          data: @members.map do |workspace_user|
            {
              id: workspace_user.id,
              user_id: workspace_user.user_id,
              email: workspace_user.user.email,
              name: workspace_user.user.name,
              role: workspace_user.role.role_name,
              created_at: workspace_user.created_at
            }
          end
        }
      end

      # POST /api/v1/workspaces/:workspace_id/members
      def create  
        # Find user by email - check both formats
        email = params[:email] || params.dig(:user, :email)        
        user = User.find_by(email: email)

        # Return error if user not found
        unless user
          render json: { error: "User not found with email: #{email}" }, status: :not_found
          return
        end

        # Check if user is already a member of this workspace
        if @workspace.users.include?(user)
          render json: { error: "User is already a member of this workspace" }, status: :conflict
          return
        end

        # Find the default member role (assuming a 'Member' role exists)
        member_role = Role.find_by(role_name: "Member")
        
        unless member_role
          render json: { error: "Member role not found" }, status: :unprocessable_entity
          return
        end

        # Create workspace user association
        workspace_user = WorkspaceUser.new(
          workspace: @workspace,
          user: user,
          role: member_role
        )

        if workspace_user.save
          render json: {
            message: "User added successfully",
            data: {
              id: workspace_user.id,
              user_id: user.id,
              email: user.email,
              name: user.name,
              role: member_role.role_name
            }
          }, status: :created
        else
          render json: { error: workspace_user.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      private

      def set_workspace
        @workspace = Workspace.find(params[:workspace_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Workspace not found" }, status: :not_found
        # Return false to halt the filter chain
        return false
      end

      def authorize_admin
        workspace_user = current_user.workspace_users.find_by(workspace: @workspace)
        
        unless workspace_user&.admin?
          render json: { error: "You don't have permission to add members to this workspace" }, status: :forbidden
          # Return false to halt the filter chain
          return false
        end
      end
    end
  end
end
