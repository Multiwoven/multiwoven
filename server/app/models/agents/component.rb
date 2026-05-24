# frozen_string_literal: true

module Agents
  class Component < ApplicationRecord
    belongs_to :workflow
    belongs_to :workspace

    has_many :source_edges, class_name: "Agents::Edge", foreign_key: "source_component_id", dependent: :destroy,
                            inverse_of: :source_component
    has_many :target_edges, class_name: "Agents::Edge", foreign_key: "target_component_id", dependent: :destroy,
                            inverse_of: :target_component

    enum component_type: { chat_input: 0, chat_output: 1, data_storage: 2, llm_model: 3, prompt_template: 4,
<<<<<<< HEAD
                           vector_store: 5, python_custom: 6 }
=======
                           vector_store: 5, python_custom: 6, conditional: 7, guardrails: 8, tool: 9, agent: 10,
                           knowledge_base: 11, llm_router: 12, human_in_loop: 13, a2a_agent: 14 }
>>>>>>> afa98e94b (feat(CE): add a2a_agent component type, masked config, and JSON-RPC client (#1719))

    validates :name, presence: true
    validates :component_type, presence: true

    store :position, coder: JSON

    # Returns configuration with auth_config values masked for API responses.
    # Currently applies to :a2a_agent components and masks all non-blank strings under auth_config.
    def masked_configuration
      return configuration if configuration.blank?
      return configuration unless a2a_agent?

      mask_a2a_secrets(configuration.deep_dup)
    end

    private

    SECRET_MASK = "*************"

    def mask_a2a_secrets(config)
      config["auth_config"] = mask_nested_values(config["auth_config"]) if config["auth_config"].present?
      config
    end

    def mask_nested_values(obj)
      case obj
      when Hash
        obj.transform_values { |v| mask_nested_values(v) }
      when Array
        obj.map { |v| mask_nested_values(v) }
      when String
        obj.present? ? SECRET_MASK : obj
      else
        obj
      end
    end
  end
end
