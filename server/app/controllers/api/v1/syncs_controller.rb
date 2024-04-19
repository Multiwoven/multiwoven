# frozen_string_literal: true

module Api
  module V1
    class SyncsController < ApplicationController
      include Syncs
      before_action :set_sync, only: %i[show update destroy]
      before_action :modify_sync_params, only: %i[create update]

      after_action :event_logger

      attr_reader :sync

      def index
        @syncs = current_workspace
                 .syncs.all.page(params[:page] || 1)
        render json: @syncs, status: :ok
      end

      def show
        render json: @sync, status: :ok
      end

      def create
        result = CreateSync.call(
          workspace: current_workspace,
          sync_params:
        )

        if result.success?
          @sync = result.sync
          render json: @sync, status: :created
        else
          render_error(
            message: "Sync creation failed",
            status: :unprocessable_entity,
            details: format_errors(result.sync)
          )
        end
      end

      def update
        result = UpdateSync.call(
          sync:,
          sync_params:
        )

        if result.success?
          @sync = result.sync
          render json: @sync, status: :ok
        else
          render_error(
            message: "Sync update failed",
            status: :unprocessable_entity,
            details: format_errors(result.sync)
          )
        end
      end

      def destroy
        sync.discard
        head :no_content
      end

      # TODO: Sync trigger API
      # def trigger; end

      def configurations
        result = SyncConfigurations.call

        if result.success?
          render json: result.configurations, status: :ok
        elsif result.failure?
          render_error(
            message: "Unable to fetch sync configurations",
            status: :unprocessable_entity,
            details: format_errors(result.error)
          )
        end
      end

      private

      def set_sync
        @sync = current_workspace.syncs.find(params[:id])
      end

      def modify_sync_params
        case params[:sync][:schedule_type]
        when "cron_expression"
          params[:sync][:sync_interval] = nil
          params[:sync][:sync_interval_unit] = nil
        when "interval"
          params[:sync][:cron_expression] = nil
        when "manual"
          params[:sync][:sync_interval] = nil
          params[:sync][:sync_interval_unit] = nil
          params[:sync][:cron_expression] = nil
        end
      end

      def sync_params
        strong_params = params.require(:sync)
                              .permit(:source_id,
                                      :destination_id,
                                      :model_id,
                                      :schedule_type,
                                      :sync_interval,
                                      :sync_mode,
                                      :sync_interval_unit,
                                      :cron_expression,
                                      :stream_name,
                                      :cursor_field,
                                      configuration: %i[from
                                                        to
                                                        mapping_type
                                                        value
                                                        value_type
                                                        template])

        # TODO: Need to remove this once we implement template and static mapping in frontend
        if params.to_unsafe_h[:sync][:configuration].is_a?(Hash)
          strong_params.merge!(configuration: params.to_unsafe_h[:sync][:configuration])
        end
        strong_params.delete(:cursor_field) if action_name == "update"
        strong_params
      end
    end
  end
end
