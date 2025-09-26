# frozen_string_literal: true

FactoryBot.define do
  factory :feedback do
    data_app { create(:data_app) }
    visual_component { create(:visual_component) }
    association :workspace
    session_id { SecureRandom.hex(10) }
    feedback_type { "thumbs" }
    reaction { "positive" }

    created_at { Time.zone.now }
  end
end
