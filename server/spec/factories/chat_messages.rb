# frozen_string_literal: true

FactoryBot.define do
  factory :chat_message do
    content { "MyText" }
    role { 0 }

    association :workspace
    association :data_app_session
    association :visual_component

    created_at { Time.current }
    updated_at { Time.current }
  end
end
