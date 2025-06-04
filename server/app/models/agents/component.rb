# frozen_string_literal: true

module Agents
  class Component < ApplicationRecord
    belongs_to :workflow
    belongs_to :workspace

    enum component_type: { chat_input: 0, prompt_template: 1, sql_db: 2, vector_db: 3, model_inference: 4 }

    validates :name, presence: true
    validates :component_type, presence: true
    validates :configuration, presence: true

    store :position, coder: JSON
  end
end
