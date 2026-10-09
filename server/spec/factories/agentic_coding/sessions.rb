# frozen_string_literal: true

FactoryBot.define do
  factory :agentic_coding_session, class: "AgenticCoding::Session" do
    association :agentic_coding_app
    workspace { agentic_coding_app.workspace }
    user { agentic_coding_app.user }
    title { "Test Session" }
    status { :active }
    sandbox_id { nil }
    coding_agent_session_id { nil }
    preview_url { nil }
    agent_model { "claude-sonnet-4-20250514" }
    configuration { {} }
    last_active_at { nil }
    suspended_at { nil }

    trait :active do
      status { :active }
      sandbox_id { "sandbox-#{SecureRandom.hex(4)}" }
      coding_agent_session_id { "session-#{SecureRandom.hex(4)}" }
      preview_url { "http://localhost:5173" }
      configuration { { "sandbox_url" => "http://localhost:4096" } }
    end

    trait :paused do
      status { :paused }
      sandbox_id { "sandbox-#{SecureRandom.hex(4)}" }
      suspended_at { Time.current }
    end

    trait :ended do
      status { :ended }
    end
  end
end
