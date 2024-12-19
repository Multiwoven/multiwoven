# frozen_string_literal: true

module Api
  module V1
    class SyncRecordsController < ApplicationController
      before_action :set_sync
      before_action :set_sync_run
      attr_reader :sync, :sync_run

      def index
        sync_records = @sync_run.sync_records.order(created_at: :asc)
        authorize sync_records
        sync_records = sync_records.where(status: params[:status]) if params[:status].present?
        sync_records = sync_records.page(params[:page] || 1).per(params[:per_page])
        render json: sync_records, status: :ok
      end

      private

      def set_sync
        @sync = current_workspace.syncs.find_by(id: params[:sync_id])
        render_error(message: "Sync not found", status: :not_found) unless @sync
      end

      def set_sync_run
        @sync_run = @sync&.sync_runs&.find_by(id: params[:sync_run_id])
        render_error(message: "SyncRun not found", status: :not_found) unless @sync_run
      end
    end
  end
end
