# frozen_string_literal: true

module Api
  module V1
    class UsersController < ApplicationController
      def me
        render json: current_user, serializer: UserSerializer, workspace_id: current_workspace.id
      end
    end
  end
end
