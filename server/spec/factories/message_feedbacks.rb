# frozen_string_literal: true

FactoryBot.define do
  factory :message_feedback do
    association :data_app
    association :visual_component
    association :workspace
    association :model
    feedback_type { "thumbs" }
    reaction { "positive" }
    chatbot_interaction { { user_query: "Hello", chatbot_reply: "Hi! How can I assist you!" } }

    created_at { Time.zone.now }
  end
end
