# frozen_string_literal: true

module AuditLogger
  extend ActiveSupport::Concern
  def audit!(action: nil, user: nil, resource_type: nil, resource_id: nil, resource: nil, workspace: nil, payload: {}) # rubocop:disable Metrics/ParameterLists
    action ||= action_name
    resource_type ||= controller_name.singularize.capitalize
    user ||= current_user
    workspace ||= current_workspace

    begin
      AuditLog.create(
        user:,
        action:,
        resource_type:,
        resource_id:,
        resource:,
        workspace:,
        metadata: payload ? payload.to_unsafe_h : {}
      )
    rescue StandardError => e
      Rails.logger.error({
        error_message: e.message,
        stack_trace: Rails.backtrace_cleaner.clean(e.backtrace)
      }.to_s)
    end
  end
end
