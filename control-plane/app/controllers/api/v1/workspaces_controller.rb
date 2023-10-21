# frozen_string_literal: true

module Api
  module V1
    class WorkspacesController < ApplicationController
      before_action :set_workspace, only: %i[show update destroy]

      # GET /workspaces
      def index
        @workspaces = Workspace.all
      end

      # GET /workspaces/:id
      def show; end

      # POST /workspaces
      def create
        @workspace = Workspace.new(workspace_params)

        if @workspace.save
          render :show, status: :created
        else
          render json: { errors: @workspace.errors }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /workspaces/:id
      def update
        if @workspace.update(workspace_params)
          render :show, status: :ok
        else
          render json: { errors: @workspace.errors }, status: :unprocessable_entity
        end
      end

      # DELETE /workspaces/:id
      def destroy
        @workspace.destroy!
        head :no_content
      end

      private

      def set_workspace
        @workspace = Workspace.find(params[:id])
      end

      def workspace_params
        params.require(:workspace).permit(:name)
      end
    end
  end
end
