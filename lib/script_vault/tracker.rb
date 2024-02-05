# frozen_string_literal: true

module ScriptVault
  module Tracker
    def self.included(base)
      base.send :define_method, :dispatch_details do |event_data|
        if ENV["TRACK"] != "no"
          uri = URI(Rails.application.secrets.event_logger_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
          request.body = event_data.to_json
          http.request(request)
        end
      rescue StandardError
        Rails.logger.error "Failed to transmit data: #{e.message}"
      end
      base.send(:private, :dispatch_details)
    end

    def _track_event(event_name, properties = {})
      metadata = { distinct_id: current_user.unique_id, insert_id: SecureRandom.uuid,
                   email: current_user.email, name: current_user.name,
                   organization_name: current_organization.name, workspace_name: current_workspace.name }
      event_data = {
        event_name:,
        properties: properties.merge(metadata),
        organization_id: current_organization.id,
        workspace_id: current_workspace.id,
        user_id: current_user.id
      }

      external_event_data = event_data.dup
      dispatch_details(external_event_data)
    rescue StandardError
      Rails.logger.error "Failed to transmit data: #{e.message}"
    end
  end
end
