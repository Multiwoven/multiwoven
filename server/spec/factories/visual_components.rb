# frozen_string_literal: true

FactoryBot.define do
  factory :visual_component do
    component_type { "doughnut" }
    name { "Sales Chart" }
    model_id { "1" }
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
    association :model
    association :workspace
    association :data_app
  end
end
