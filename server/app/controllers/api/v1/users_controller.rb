# frozen_string_literal: true

module Api
  module V1
    class UsersController < ApplicationController
      include AuditLogger
      after_action :create_audit_log

      def me
        authorize current_user
        render json: current_user, serializer: UserSerializer, workspace_id: current_workspace.id
      end

      private

      def create_audit_log
        audit!(resource_id: params[:id])
      end
    end
  end
end
