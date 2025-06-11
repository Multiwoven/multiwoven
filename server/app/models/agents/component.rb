# frozen_string_literal: true

module Agents
  class Component < ApplicationRecord
    belongs_to :workflow
    belongs_to :workspace

    enum component_type: { chat_input: 0, chat_output: 1, data_storage: 2, llm_model: 3, prompt_template: 4,
                           vector_store: 5 }

    validates :name, presence: true
    validates :component_type, presence: true
    validates :configuration, presence: true

    store :position, coder: JSON
  end
end
