# frozen_string_literal: true

FactoryBot.define do
  factory :audit_log do
    action { "show" }
    resource_type { "Sync" }
    resource_id { 1 }
    resource { "Test_Sync" }
    metadata { nil }
    created_at { Time.current }
    updated_at { Time.current }
    resource_link { "api/test_link" }

    association :workspace
    association :user
  end
end
