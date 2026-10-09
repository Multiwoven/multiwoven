# frozen_string_literal: true

module Connectors
  class DeleteConnector
    include Interactor

    def call
      check_dependencies
      delete_connector if context.success?
    end

    private

    def check_dependencies
      dependencies = []
      dependencies << "models" if context.connector.models.exists?
      dependencies << "workflow components" if used_in_workflow_components?

      return if dependencies.empty?

      context.fail!(
        error: "Cannot delete connector. This connector is used in #{dependencies.join(', ')}. " \
               "Please delete or update the associated resources first."
      )
    end

    def used_in_workflow_components?
      # Check if connector is referenced in any workflow component configurations
      Agents::Component.where(workspace_id: context.connector.workspace_id).find_each do |component|
        config = component.configuration || {}
        connector_keys = %w[llm_model database llm_connector_id judge_llm_connector_id]
        return true if connector_keys.any? { |key| config[key]&.to_i == context.connector.id }
      end
      false
    end

    def delete_connector
      context.connector.destroy!
    end
  end
end
