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
                           vector_store: 5 }

    validates :name, presence: true
    validates :component_type, presence: true

    store :position, coder: JSON
  end
end
