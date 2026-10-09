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
                           vector_store: 5, python_custom: 6 }

    validates :name, presence: true
    validates :component_type, presence: true

    store :position, coder: JSON
<<<<<<< HEAD
=======

    # Returns configuration with auth_config values masked for API responses.
    # Currently applies to :a2a_agent components and masks all non-blank strings under auth_config.
    def masked_configuration
      return configuration if configuration.blank?
      return mask_secrets(configuration.deep_dup) if a2a_agent? || vector_store?

      configuration
    end

    private

    def mask_secrets(config)
      config["api_key"] = Utils::SecretMasking::MASKED_VALUE if config["api_key"].present?
      if config["auth_config"].present?
        config["auth_config"] =
          Utils::SecretMasking.mask_nested_values(config["auth_config"])
      end
      config
    end
>>>>>>> 2d3e49530 (fix(CE): added masking configuration for vector store (#1855))
  end
end
