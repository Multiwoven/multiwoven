# frozen_string_literal: true

FactoryBot.define do
  factory :feedback do
    association :data_app
    association :visual_component
    association :workspace
    association :model
    session_id { SecureRandom.hex(10) }
    feedback_type { "thumbs" }
    reaction { "positive" }
  end
end
