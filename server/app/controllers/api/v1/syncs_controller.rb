# frozen_string_literal: true

module Api
  module V1
    # rubocop:disable Metrics/ClassLength
    class SyncsController < ApplicationController
      include Syncs
      include AuditLogger
      include ResourceLinkBuilder
      before_action :set_sync, only: %i[show update enable destroy]
      before_action :modify_sync_params, only: %i[create update]

      after_action :event_logger
      after_action :create_audit_log, only: %i[create update enable destroy]

      attr_reader :sync

      def index
        @syncs = current_workspace
                 .syncs.all.page(params[:page] || 1)
        authorize @syncs
        render json: @syncs, status: :ok
      end

      def show
        authorize @sync
        @audit_resource = @sync.name
        render json: @sync, status: :ok
      end

      def create
        authorize current_workspace, policy_class: SyncPolicy
        result = CreateSync.call(
          workspace: current_workspace,
          sync_params:
        )

        if result.success?
          @sync = result.sync
          @audit_resource = @sync.name
          @resource_id = @sync.id
          @payload = sync_params
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
        authorize current_workspace, policy_class: SyncPolicy
        result = UpdateSync.call(
          sync:,
          sync_params:
        )

        if result.success?
          @sync = result.sync
          @audit_resource = @sync.name
          @payload = sync_params
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
        authorize sync
        @action = "delete"
        @audit_resource = sync.name
        sync.discard
        head :no_content
      end

      # TODO: Sync trigger API
      # def trigger; end

      def configurations
        result = SyncConfigurations.call
        authorize result, policy_class: SyncPolicy
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

      def enable
        authorize current_workspace, policy_class: SyncPolicy
        params[:enable] ? @sync.enable : @sync.disable
        if @sync.save
          @audit_resource = @sync.name
          render json: @sync, status: :ok
        else
          render_error(message: "Sync update failed", status: :unprocessable_entity,
                       details: format_errors(result.sync))
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

      def create_audit_log
        resource_id = @resource_id || params[:id]
        resource_link = @action == "delete" ? nil : build_link!(resource_id:)
        audit!(action: @action, resource_id:, resource: @audit_resource, payload: @payload, resource_link:)
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
    # rubocop:enable Metrics/ClassLength
  end
end
