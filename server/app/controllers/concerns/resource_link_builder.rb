# frozen_string_literal: true

module ResourceLinkBuilder
  # rubocop:disable Metrics/CyclomaticComplexity
  extend ActiveSupport::Concern
  def build_link!(resource_type: nil, resource: nil, resource_id: nil)
    resource_type ||= controller_name.singularize.capitalize
    case resource_type
    when "Catalog", "Connector"
      connectors_link(resource, resource_id)
    when "Model"
      models_link(resource, resource_id)
    when "Schedule_sync", "Sync"
      syncs_link(resource_id)
    when "Data_app", "Custom_visual_component"
      data_apps_link(resource_id)
    when "Profile", "User"
      members_link
    else
      reports_link(resource_id)
    end
  rescue StandardError => e
    Rails.logger.error({
      error_message: e.message,
      stack_trace: Rails.backtrace_cleaner.clean(e.backtrace)
    }.to_s)
    nil
  end

  private

  def connectors_link(resource, resource_id)
    case resource.connector_type
    when "source"
      if resource.connector_category == "AI Model"
        "/setup/sources/AIML%20Sources/#{resource_id}"
      else
        "/setup/sources/Data%20Sources/#{resource_id}"
      end
    else
      "/setup/destinations/#{resource_id}"
    end
  end

  def models_link(resource, resource_id)
    case resource.query_type
    when "ai_ml"
      "/define/models/ai/#{resource_id}"
    else
      "/define/models/#{resource_id}"
    end
  end

  def syncs_link(resource_id)
    "/activate/syncs/#{resource_id}"
  end

  def data_apps_link(resource_id)
    "/data-apps/list/#{resource_id}"
  end

  def members_link
    "/settings/members"
  end

  def reports_link(resource_id)
    "/reports/#{resource_id}"
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
