# frozen_string_literal: true

FactoryBot.define do
  factory :spending_limit do
    association :workspace
    association :created_by, factory: :user

    organization { workspace.organization }
    sequence(:name) { |n| "Spend limit #{n}" }
    level { :limit }
    scope_type { :workspace }
    scope_ids { [] }
    providers { [] }
    models { [] }
    limit_type { :cost }
    cost_limit { 100.0 }
    token_limit { nil }
    period { :monthly }
    alert_thresholds { [80, 90] }
    action_on_exhaust { :warn }
    enabled { true }

    trait :allocation do
      level { :allocation }
      name { SpendingLimit::ALLOCATION_NAME }
      action_on_exhaust { :block }
    end

    trait :blocking do
      action_on_exhaust { :block }
    end

    trait :disabled do
      enabled { false }
    end

    trait :with_token_limit do
      limit_type { :tokens }
      cost_limit { nil }
      token_limit { 10_000_000 }
    end

    trait :with_both_limits do
      limit_type { :both }
      cost_limit { 100.0 }
      token_limit { 10_000_000 }
    end
  end
end
