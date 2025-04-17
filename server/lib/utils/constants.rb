# frozen_string_literal: true

module Utils
  module Constants
    # whenever resource group mappung is updated
    # enterpise role contracts need to be updated also
    RESOURCE_GROUP_MAPPING = {
      "Alerts" => {
        resources: [:alerts],
        description: "Manage and access alerts on syncs"
      },
      "Billing" => {
        resources: [:billing],
        description: "Manage and access billing for your organization"
      },
      "Connectors" => {
        resources: %i[connector_definition connector],
        description: "Manage and access sources and destinations"
      },
      "Models" => {
        resources: [:model],
        description: "Manage and access models"
      },
      "Syncs" => {
        resources: %i[sync sync_run sync_record],
        description: "Manage and access syncs"
      },
      "Data Apps" => {
        resources: [:data_app], description: "Manage and access data apps"
      },
      "Reports" => {
        resources: [:report],
        description: "Manage and access reports for syncs and data apps"
      },
      "Workspace Management" => {
        resources: %i[user audit_logs workspace],
        description: "Manage and access workspaces, members, and audit logs"
      },
      "Organization Management" => {
        resources: %i[sso eula],
        description: "Manage organization SSO settings and EULA configurations"
      },
      "Assistant" => {
        resources: %i[assistant],
        description: "Manage and access the AI assistant and its configurations"
      }
    }.freeze
  end
end
