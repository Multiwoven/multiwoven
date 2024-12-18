# frozen_string_literal: true

module Api
  module V1
    class SyncRunsController < ApplicationController
      before_action :set_sync
      before_action :set_sync_run, only: [:show]
      attr_reader :sync

      def index
        sync_runs = @sync.sync_runs.order(started_at: :desc)
        authorize sync_runs
        sync_runs = sync_runs.where(status: params[:status]) if params[:status].present?
        sync_runs = sync_runs.page(params[:page] || 1).per(params[:per_page])
        render json: sync_runs, status: :ok
      end

      def show
        authorize @sync_run
        render json: @sync_run, status: :ok
      end

      private

      def set_sync
        @sync = current_workspace.syncs.find_by(id: params[:sync_id])
        render_error(message: "Sync not found", status: :not_found) unless @sync
      end

      def set_sync_run
        @sync_run = @sync.sync_runs.find_by(id: params[:id])
        render_error(message: "Sync Run not found", status: :not_found) unless @sync_run
      end
    end
  end
end
