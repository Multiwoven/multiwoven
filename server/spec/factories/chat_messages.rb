# frozen_string_literal: true

FactoryBot.define do
  factory :chat_message do
    content { "MyText" }
    role { 0 }

    association :workspace

    trait :data_app_session do
      association :session, factory: :data_app_session
      visual_component { association :visual_component }
    end

    trait :workflow_session do
      association :session, factory: :workflow_session
      workflow { association :workflow }
    end

    created_at { Time.current }
    updated_at { Time.current }
  end
end
