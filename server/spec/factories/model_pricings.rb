# frozen_string_literal: true

FactoryBot.define do
  factory :model_pricing do
    provider { "openai" }
    sequence(:model) { |n| "gpt-test-#{n}" }
    input_rate { 0.0000030 }
    output_rate { 0.0000120 }
    cache_read_rate { 0.0000003 }
    cache_write_rate { 0.0000037 }
    currency { "USD" }
    source { :sync }
    effective_from { 1.day.ago }
    effective_to { nil }

    trait :manual do
      source { :manual }
    end

    trait :closed do
      effective_to { Time.current }
    end
  end
end
