# frozen_string_literal: true

module Agents
  class Tool < ApplicationRecord
    MCP_CONFIG_JSON_SCHEMA = Rails.root.join(
      "app/models/schema_validations/tools/mcp.json"
    )

    belongs_to :workspace

    enum :tool_type, { mcp: 0 }

    validates :name, presence: true, uniqueness: { scope: :workspace_id, case_sensitive: false }
    validates :tool_type, presence: true
    validates :configuration, presence: true, json: { schema: -> { configuration_schema } }

    default_scope { order(updated_at: :desc) }

    # Returns connection config for MCP tools
    # Used by MCP client to establish connection
    def connection_config
      return {} unless mcp? && configuration.present?

      cfg = configuration.with_indifferent_access
      {
        url: cfg["url"],
        transport: cfg["transport"],
        auth_type: cfg["auth_type"],
        auth_config: cfg["auth_config"] || {},
        headers: cfg["headers"] || {},
        timeout: cfg["timeout"] || 30
      }.compact
    end

    # Mask sensitive configuration values for API responses
    def masked_configuration
      return configuration if configuration.blank?

      mask_mcp_secrets(configuration.deep_dup)
    end

    private

    def configuration_schema
      MCP_CONFIG_JSON_SCHEMA
    end

    def mask_mcp_secrets(config)
      if config["auth_config"].present?
        config["auth_config"] = config["auth_config"].transform_values do |value|
          value.is_a?(String) && value.present? ? "*************" : value
        end
      end
      config
    end
  end
end
