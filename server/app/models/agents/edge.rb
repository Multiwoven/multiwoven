# frozen_string_literal: true

module Agents
  class Edge < ApplicationRecord
    belongs_to :workflow
    belongs_to :workspace
    belongs_to :source_component, class_name: "Agents::Component"
    belongs_to :target_component, class_name: "Agents::Component"

    validates :source_handle, presence: true
    validates :target_handle, presence: true

    store :source_handle, coder: JSON
    store :target_handle, coder: JSON
  end
end
