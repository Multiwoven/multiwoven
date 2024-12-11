# frozen_string_literal: true

module AuditLogger
  extend ActiveSupport::Concern
  # rubocop:disable Metrics/CyclomaticComplexity
  def audit!(options = {}) # rubocop:disable Metrics/PerceivedComplexity
    action = options[:action] || action_name
    resource_type = options[:resource_type] || controller_name.singularize.capitalize
    resource_id = options[:resource_id] || nil
    resource = options[:resource] || nil
    user = options[:user] || current_user
    workspace = options[:workspace] || current_workspace
    payload = options[:payload] || {}
    resource_link = options[:resource_link] || nil

    begin
      AuditLog.create(
        user:,
        action:,
        resource_type:,
        resource_id:,
        resource:,
        workspace:,
        metadata: payload.try(:to_unsafe_h) || payload,
        resource_link:
      )
    rescue StandardError => e
      Rails.logger.error({
        error_message: e.message,
        stack_trace: Rails.backtrace_cleaner.clean(e.backtrace)
      }.to_s)
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
