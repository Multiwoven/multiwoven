# frozen_string_literal: true

FactoryBot.define do
  factory :visual_component do
    component_type { "doughnut" }
    name { "Sales Chart" }
    properties do
      {
        color: "blue"
      }
    end
    feedback_config do
      {
        enabled: true
      }
    end
    association :configurable, factory: :model
    association :workspace
    association :data_app
  end
end
