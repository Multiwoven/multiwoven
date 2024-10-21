# frozen_string_literal: true

module Enterprise
  module Api
    module V1
      class SyncsController < EnterpriseBaseController
        include Syncs
        include AuditLogger
        before_action :set_sync
        before_action :validate_sync_status
        after_action :create_audit_log

        attr_reader :sync

        def test
          authorize @sync, policy_class: EnterpriseSyncPolicy
          result = TestSync.call(sync: @sync)

          if result.success?
            @audit_resource = @sync.name
            render json: { message: "Sync test triggered successful" }, status: :ok
          else
            render_error(
              message: "Sync test failed",
              status: :unprocessable_entity,
              details: format_errors(@sync)
            )
          end
        end

        private

        def validate_sync_status
          return unless @sync.disabled?

          render_error(message: "Sync is disabled",
                       status: :failed_dependency)
        end

        def set_sync
          @sync = current_workspace.syncs.find_by(id: params[:id])
          render_error(message: "Sync not found", status: :not_found) unless @sync
        end

        def create_audit_log
          audit!(resource_id: params[:id], resource: @audit_resource, payload: @payload)
        end
      end
    end
  end
end
