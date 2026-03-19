# frozen_string_literal: true

module Agents
  class WorkflowIntegration < ApplicationRecord
    SLACK_CONFIG_JSON_SCHEMA = Rails.root.join("app/models/schema_validations/integrations/configuration_slack.json")

    belongs_to :workflow, class_name: "Agents::Workflow"
    belongs_to :workspace

    enum app_type: { slack: 0 }

    validates :connection_configuration, presence: true, json: { schema: lambda {
                                                                           connection_configuration_schema_validation
                                                                         } }, if: :requires_configuration?

    validates :workflow_id, :workspace_id, :app_type, :metadata, presence: true

    def requires_configuration?
      %w[slack].include?(app_type)
    end

    def connection_configuration_schema_validation
      return unless slack?

      SLACK_CONFIG_JSON_SCHEMA
    end
  end
end
