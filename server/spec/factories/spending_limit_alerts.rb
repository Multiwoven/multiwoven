# frozen_string_literal: true

FactoryBot.define do
  factory :spending_limit_alert do
    association :spending_limit_counter

    threshold { 80 }
    delivered_at { nil }

    trait :delivered do
      delivered_at { Time.current }
    end
  end
end
