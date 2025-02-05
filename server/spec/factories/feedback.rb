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
<<<<<<< HEAD:server/spec/factories/feedback.rb
=======
    chatbot_interaction { { user_query: "Hello", chatbot_reply: "Hi! How can I assist you!" } }

    created_at { Time.zone.now }
>>>>>>> 0c8585c2 (chore(CE): Update Message Feedback Factory (#835)):server/spec/factories/message_feedbacks.rb
  end
end
