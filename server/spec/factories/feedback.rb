# frozen_string_literal: true

FactoryBot.define do
  factory :feedback do
    data_app { create(:data_app) }
    visual_component { create(:visual_component) }
    model { create(:model) }
    association :workspace
    session_id { SecureRandom.hex(10) }
    feedback_type { "thumbs" }
    reaction { "positive" }
<<<<<<< HEAD
<<<<<<< HEAD:server/spec/factories/feedback.rb
=======
    chatbot_interaction { { user_query: "Hello", chatbot_reply: "Hi! How can I assist you!" } }

    created_at { Time.zone.now }
>>>>>>> 0c8585c2 (chore(CE): Update Message Feedback Factory (#835)):server/spec/factories/message_feedbacks.rb
=======

    created_at { Time.zone.now }
>>>>>>> main
  end
end
