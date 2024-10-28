# frozen_string_literal: true

module Api
  module V1
    class ReportsController < ApplicationController
      include Reports
      include AuditLogger
      after_action :create_audit_log
      attr_reader :report

      def index
        authorize current_workspace, policy_class: ReportPolicy
        result = ActivityReport.call(report_params)

        if result.success?
          render json: result.workspace_activity, status: :ok
        else
          render_error(message: result.error, status: :unprocessable_entity)
        end
      end

      private

      def create_audit_log
        audit!
      end

      def report_params
        params.permit(:type, :time_period, :metric, connector_ids: []).merge(workspace: current_workspace)
      end
    end
  end
end
