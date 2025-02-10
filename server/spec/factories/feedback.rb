# frozen_string_literal: true

FactoryBot.define do
  factory :feedback do
    association :data_app
    association :visual_component
    association :workspace
    association :model
    feedback_type { "thumbs" }
    reaction { "positive" }
  end
end
