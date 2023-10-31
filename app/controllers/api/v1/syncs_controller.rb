# frozen_string_literal: true

module Api
  module V1
    class SyncsController < ApplicationController
      include Syncs
      before_action :set_sync, only: %i[show update destroy]

      attr_reader :sync

      def index
        @syncs = current_workspace
                 .syncs.all.page(params[:page] || 1)
      end

      def show; end

      def create
        result = CreateSync.call(
          workspace: current_workspace,
          sync_params:
        )

        if result.success?
          @sync = result.sync
        else
          render json: { errors: result.errors },
                 status: :unprocessable_entity
        end
      end

      def update
        result = UpdateSync.call(
          sync:,
          sync_params:
        )

        if result.success?
          @sync = result.sync
        else
          render json: { errors: result.errors },
                 status: :unprocessable_entity
        end
      end

      def destroy
        sync.destroy!
        head :no_content
      end

      # TODO: Sync trigger API
      # def trigger; end

      private

      def set_sync
        @sync = current_workspace.syncs.find(params[:id])
      end

      def sync_params
        params.require(:sync).permit(:source_id,
                                     :destination_id,
                                     :model_id,
                                     :schedule_type,
                                     :status,
                                     configuration: {},
                                     schedule_data: {})
              .merge(workspace_id: current_workspace.id)
      end
    end
  end
end
