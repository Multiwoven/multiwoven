# frozen_string_literal: true

module Api
  module V1
    class SyncRunsController < ApplicationController
      before_action :set_sync, only: [:index]
      attr_reader :sync

      def index
        sync_runs = @sync.sync_runs
        sync_runs = sync_runs.where(status: params[:status]) if params[:status].present?
        sync_runs = sync_runs.page(params[:page] || 1)
        render json: sync_runs, status: :ok
      end

      private

      def set_sync
        @sync = current_workspace.syncs.find_by(id: params[:sync_id])
        render_error(message: "Sync not found", status: :not_found) unless @sync
      end
    end
  end
end
