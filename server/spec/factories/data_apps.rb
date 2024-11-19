# frozen_string_literal: true

FactoryBot.define do
  factory :data_app do
    name { "Sales Dashboard" }
    description { "A dashboard for visualizing sales data" }
    status { "active" }
    rendering_type { "embed" }
    meta_data do
      {
        author: "John Doe",
        version: "1.0"
      }
    end
    association :workspace

    transient do
      visual_components_count { 1 }
    end

    after(:create) do |data_app, evaluator|
      if evaluator.visual_components_count > 0
        create_list(:visual_component, evaluator.visual_components_count, data_app:)
      end
    end
  end
end
