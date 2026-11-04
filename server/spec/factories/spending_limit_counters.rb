# frozen_string_literal: true

FactoryBot.define do
  factory :spending_limit_counter do
    association :spending_limit

    window_start { SpendingLimits::CounterStore.window_start(spending_limit.period) }
    spent_cost { 0 }
    spent_tokens { 0 }
    request_count { 0 }
    unpriced_requests { 0 }
    alerted_thresholds { [] }
  end
end
