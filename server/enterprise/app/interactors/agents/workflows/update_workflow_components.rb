# frozen_string_literal: true

module Agents
  module Workflows
    class UpdateWorkflowComponents
      include Interactor

      delegate :workflow, :components_params, to: :context

      def call
        # Get IDs of components in the update params
        updated_component_ids = components_params.map { |params| params[:id] }

        # Delete components that are not in the update params
        workflow.components.where.not(id: updated_component_ids).find_each do |component|
          set_knowledge_base_component(component, enabled: false) if component.component_type == "knowledge_base"
          delete_file_input_files if component.component_type == "file_input"
          component.destroy!
        end

        # Update or create components from params
        components_params.each do |component_params|
          update_component(component_params)
        end
      end

      private

      def update_component(params)
        existing_component = Agents::Component.find_by(id: params[:id])
        if existing_component && existing_component.workflow_id != workflow.id
          raise StandardError, "Component with ID '#{params[:id]}' already exists in another workflow"
        end

        component = workflow.components.find_or_initialize_by(id: params[:id])
        configuration = params[:configuration]
        masked_keys = Utils::SecretMasking.masked_attribute_keys(params[:configuration])
        unless masked_keys.empty?
          configuration = configuration.respond_to?(:to_unsafe_h) ? configuration.to_unsafe_h : configuration
          configuration = configuration.except(*masked_keys).merge(component.configuration.slice(*masked_keys))
        end
        old_component = component.dup
        component.update!(
          workspace: workflow.workspace,
          name: params[:name],
          component_type: params[:component_type],
          component_category: params[:component_category],
          data: params[:data],
          configuration:,
          position: params[:position]
        )
        return unless component.component_type == "knowledge_base"

        set_knowledge_base_component(old_component, enabled: false)
        set_knowledge_base_component(component, enabled: true)
      end

      def set_knowledge_base_component(component, enabled:)
        knowledge_base_id = component.configuration&.dig("knowledge_base")
        return if knowledge_base_id.blank?

        knowledge_base = Agents::KnowledgeBase.find_by(id: knowledge_base_id)
        return if knowledge_base.nil?

        # rubocop:disable Rails/SkipsModelValidations
        knowledge_base.knowledge_base_files.update_all(workflow_enabled: enabled)
        # rubocop:enable Rails/SkipsModelValidations
      end

      def delete_file_input_files
        workflow.workflow_files.destroy_all
      end
    end
  end
end
